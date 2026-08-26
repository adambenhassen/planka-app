import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/planka_api.dart';
import '../auth/auth_providers.dart';
import '../l10n/gen/app_localizations.dart';
import 'error_handling.dart';
import 'privacy_policy.dart';
import 'widgets/confirm_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.privacyPolicyLauncher});

  final PrivacyPolicyLauncher? privacyPolicyLauncher;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverCtrl = TextEditingController(text: 'https://');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  final _codeFormKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  /// Second-factor step. The pending token is a bearer credential that buys a
  /// full access token for six digits, so it lives here and nowhere else:
  /// never on [PlankaApi.token], never in the account store, never rendered.
  /// Non-null is what puts the screen on the code step.
  String? _pendingToken;
  PlankaApi? _pendingApi;
  String? _pendingServerUrl;

  /// Step message, always authored here — the server's own `message` is never
  /// shown for a rejected code or an expired pending token.
  String? _message;

  @override
  void initState() {
    super.initState();
    // Session-expired landing: prefill the server and explain why we're here.
    final expired = ref.read(authExpiredProvider);
    if (expired != null) {
      _serverCtrl.text = expired.serverUrl;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).loginSessionExpired),
          ),
        );
        ref.read(authExpiredProvider.notifier).clear();
      });
    }
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    _clearPending();
    super.dispose();
  }

  /// Bumped every time the code step is torn down, so a verification already
  /// in flight can tell that the step it belongs to is gone. A captured client
  /// and pending token outlive the state they came from, and without this a
  /// cancel racing an in-flight submit still ends in a signed-in session.
  int _pendingEpoch = 0;

  /// True from the moment verification returns a real access token until the
  /// resulting sign-in has fully finished (profile fetch, account upsert,
  /// current-account selection). While it is true the step is "accepted and
  /// finalizing": the pending token has been spent, the screen stays on the
  /// code step with its spinner, and Cancel must be inert. It is what keeps a
  /// stale Cancel callback captured before acceptance from tearing down an
  /// already-accepted session and from swallowing the error an in-flight
  /// finalization throws.
  bool _finalizing = false;

  /// Drops the pending token and everything that could still spend it. Called
  /// on every exit from the code step — success, expiry, cancel and dispose.
  void _clearPending() {
    _pendingToken = null;
    _pendingApi = null;
    _pendingServerUrl = null;
    _pendingEpoch++;
  }

  /// Logs in, handling a fresh server's Terms-of-Service step and a
  /// two-factor-enabled account's code step. Returns false when login did not
  /// finish here — the user declined the terms, the widget was disposed
  /// mid-flow, or the code step has taken over. None of those is an error.
  Future<bool> _authenticate(PlankaApi api, String serverUrl) async {
    final email = _emailCtrl.text.trim();
    try {
      try {
        await api.login(email, _passwordCtrl.text);
      } on TermsRequiredException catch (e) {
        if (!mounted || !await _confirmTerms()) return false;
        await api.acceptTerms(e.pendingToken); // returns & stores the token
      }
    } on TotpRequiredException catch (e) {
      // Hand the pending token to the code step, in memory only. The login is
      // not finished and not failed — it continues there.
      if (!mounted) return false;
      setState(() {
        _pendingApi = api;
        _pendingServerUrl = serverUrl;
        _pendingToken = e.pendingToken;
        _codeCtrl.clear();
      });
      return false;
    }
    return true;
  }

  /// Submits one code per user action — never retried automatically, so the
  /// app cannot amplify a guess rate against a six-digit secret.
  Future<void> _submitCode() async {
    // Guards the entry point rather than each caller: the buttons refuse while
    // loading, but they decide that at build time, so a second Enter or tap
    // arriving before the next frame would slip past them.
    if (_loading) return;
    if (!_codeFormKey.currentState!.validate()) return;
    final api = _pendingApi;
    final pendingToken = _pendingToken;
    final serverUrl = _pendingServerUrl;
    if (api == null || pendingToken == null || serverUrl == null) return;
    var epoch = _pendingEpoch;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await api.verifyTotp(pendingToken, _codeCtrl.text.trim());
      // A cancel dispatched in the same frame as the submit gets here. The
      // request cannot be unsent, but a cancelled step must not sign anyone in.
      if (!mounted || _pendingEpoch != epoch) return;
      // Spent: a real access token is now in hand, so the step is accepted and
      // finalizing. Keep the pending fields (and the code step) alive through
      // the finalization — clearing them now would flip the screen back to
      // credentials while signIn is still running and would make a Cancel
      // landing in that window look like a real teardown. The token itself is
      // still never persisted from here; signIn persists only the full access
      // token.
      _codeCtrl.clear();
      setState(() => _finalizing = true);
      try {
        await ref.read(currentAccountProvider.notifier).signIn(api, serverUrl);
      } catch (e) {
        // A failure during an accepted finalization must still be surfaced:
        // the code is spent and the user is entitled to know why the sign-in
        // did not finish. _cancelCode is inert while finalizing, so no Cancel
        // can have changed the epoch here — this is always a real failure.
        // The step is over (the code cannot be retried), so tear it down and
        // report, exactly as a failed password-only login does.
        _clearPending();
        if (mounted) {
          setState(() => _finalizing = false);
          showApiError(context, e);
        }
        return;
      }
      // Finalization is done. Drop the step and the finalizing flag together,
      // then navigate. A Cancel that arrives after this point is just a cancel
      // of a finished login — nothing to tear down.
      _clearPending();
      if (mounted) {
        setState(() => _finalizing = false);
        context.go('/projects');
      }
    } on TotpCodeRejectedException {
      // The pending token survives a rejected code, so stay on the step and
      // let the user try again — unless that step is already gone, in which
      // case this message would land on the credentials screen.
      if (!mounted || _pendingEpoch != epoch) return;
      setState(() => _message = AppLocalizations.of(context).loginTotpRejected);
    } on TotpPendingTokenExpiredException {
      // The ten-minute window closed. Back to credentials — the password is
      // never cached, so it is typed again rather than replayed. If the step
      // was cancelled first, clearing the field would wipe whatever the user
      // has typed since.
      if (!mounted || _pendingEpoch != epoch) return;
      setState(() {
        _clearPending();
        _codeCtrl.clear();
        _passwordCtrl.clear();
        _message = AppLocalizations.of(context).loginTotpExpired;
      });
    } catch (e) {
      if (!mounted || _pendingEpoch != epoch) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Abandons the second factor and returns to credentials, keeping nothing
  /// from the attempt.
  ///
  /// Once verification has accepted a real token, cancellation no longer
  /// applies: the step is finalizing, and a Cancel landing here — whether from
  /// a live tap or a stale callback captured before acceptance — must be
  /// inert. There is no rollback or logout; the accepted flow runs to
  /// completion on its own.
  void _cancelCode() {
    if (_finalizing) return;
    setState(() {
      _clearPending();
      _codeCtrl.clear();
      _passwordCtrl.clear();
      _message = null;
    });
  }

  Future<bool> _confirmTerms() {
    final l10n = AppLocalizations.of(context);
    return confirmDialog(
      context,
      title: l10n.loginTermsTitle,
      message: l10n.loginTermsMessage,
      confirmLabel: l10n.actionAccept,
    );
  }

  Future<void> _submit() async {
    // Same entry-point guard as _submitCode: one login in flight at a time,
    // however many times Enter or the button is pressed.
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    final serverUrl = _serverCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      final api = ref.read(apiFactoryProvider)(serverUrl);
      // False: terms declined, or the second-factor step has taken over.
      if (!await _authenticate(api, serverUrl)) return;
      await ref.read(currentAccountProvider.notifier).signIn(api, serverUrl);
      if (mounted) context.go('/projects');
    } catch (e) {
      // Surface any login failure — not just ApiException. A token-save failure
      // (macOS keychain entitlement, Android keystore) throws PlatformException
      // here; without this the login button would silently no-op.
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, Colors.black, 0.35)!,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _LoginBackdropPainter(),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: _pendingToken == null && !_finalizing
                          ? _credentialsStep(l10n, theme, scheme)
                          : _codeStep(l10n, theme, scheme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Server, identity and password. Shape unchanged from before the second
  /// factor existed — this is still the screen's first frame.
  Widget _credentialsStep(
      AppLocalizations l10n, ThemeData theme, ColorScheme scheme) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icon/icon.png',
                  height: 64,
                  width: 64,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.loginSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _serverCtrl,
              decoration: InputDecoration(
                labelText: l10n.loginServerUrl,
                prefixIcon: const Icon(Icons.dns_outlined),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.url],
              validator: (v) =>
                  (v == null ||
                      v.trim().isEmpty ||
                      v.trim() == 'https://')
                  ? l10n.fieldRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: l10n.loginEmailOrUsername,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                  ? l10n.fieldRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: l10n.fieldPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? l10n.loginShowPassword
                      : l10n.loginHidePassword,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                    () =>
                        _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (v) => (v == null || v.isEmpty)
                  ? l10n.fieldRequired
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            ..._messageBlock(theme, scheme),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(l10n.loginSubmit),
            ),
            const SizedBox(height: 8),
            _privacyPolicyLink(l10n),
          ],
        ),
      ),
    );
  }

  /// The second factor. Reached only once the password was already accepted,
  /// so this replaces the credentials rather than appearing alongside them.
  Widget _codeStep(
      AppLocalizations l10n, ThemeData theme, ColorScheme scheme) {
    return Form(
      key: _codeFormKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icon/icon.png',
                  height: 64,
                  width: 64,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loginTotpTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.loginTotpSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _codeCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.loginTotpCode,
                prefixIcon: const Icon(Icons.shield_outlined),
                border: const OutlineInputBorder(),
              ),
              // A recovery code is neither six digits nor numeric, so the field
              // stays general and validation is non-empty only — a length or
              // digits-only rule would reject a valid recovery code before it
              // was ever sent. oneTimeCode with suggestions off also keeps a
              // recovery code out of the keyboard's learned dictionary.
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.oneTimeCode],
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              onFieldSubmitted: (_) => _submitCode(),
            ),
            ..._messageBlock(theme, scheme),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _loading ? null : _submitCode,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(l10n.loginTotpVerify),
            ),
            const SizedBox(height: 8),
            _privacyPolicyLink(l10n),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : _cancelCode,
              child: Text(l10n.actionCancel),
            ),
          ],
        ),
      ),
    );
  }

  /// Client-authored step message, or nothing. Spread into a step's children so
  /// that with no message the tree is byte-identical to having no message row.
  List<Widget> _messageBlock(ThemeData theme, ColorScheme scheme) {
    final message = _message;
    if (message == null) return const [];
    return [
      const SizedBox(height: 16),
      Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
      ),
    ];
  }

  Widget _privacyPolicyLink(AppLocalizations l10n) => TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () => openPrivacyPolicy(
          context,
          launcher: widget.privacyPolicyLauncher,
        ),
        child: Text(l10n.privacyPolicy),
      );
}

/// Discord-style ambient backdrop: soft translucent circles and floating
/// kanban-card shapes scattered behind the login card.
class _LoginBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glow = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(w * 0.12, h * 0.15), w * 0.35, glow);
    canvas.drawCircle(Offset(w * 0.95, h * 0.85), w * 0.45, glow);
    canvas.drawCircle(Offset(w * 0.85, h * 0.10), w * 0.18, glow);

    // Floating "cards" — a nod to the kanban board behind the door.
    final card = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (final (cx, cy, cw, angle) in [
      (0.10, 0.75, 0.16, -0.20),
      (0.88, 0.30, 0.13, 0.15),
      (0.20, 0.32, 0.10, 0.25),
      (0.80, 0.68, 0.11, -0.12),
    ]) {
      canvas.save();
      canvas.translate(w * cx, h * cy);
      canvas.rotate(angle);
      final cardW = w * cw;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: cardW,
            height: cardW * 0.62,
          ),
          Radius.circular(cardW * 0.10),
        ),
        card,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LoginBackdropPainter oldDelegate) => false;
}
