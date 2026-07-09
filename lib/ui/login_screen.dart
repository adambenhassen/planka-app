import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/planka_api.dart';
import '../auth/auth_providers.dart';
import 'error_handling.dart';
import 'widgets/confirm_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

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
          const SnackBar(content: Text('Session expired — log in again')),
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
    super.dispose();
  }

  /// Logs in, handling a fresh server's Terms-of-Service step. Returns false
  /// when the terms step cannot complete (user declined, or the widget was
  /// disposed mid-flow) — a clean cancel, not an error.
  Future<bool> _authenticate(PlankaApi api) async {
    final email = _emailCtrl.text.trim();
    try {
      await api.login(email, _passwordCtrl.text);
    } on TermsRequiredException catch (e) {
      if (!mounted || !await _confirmTerms()) return false;
      await api.acceptTerms(e.pendingToken); // returns & stores the token
    }
    return true;
  }

  Future<bool> _confirmTerms() => confirmDialog(
    context,
    title: 'Accept Terms of Service?',
    message:
        'This server requires you to accept its Terms of Service to log in.',
    confirmLabel: 'Accept',
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final serverUrl = _serverCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      final api = ref.read(apiFactoryProvider)(serverUrl);
      if (!await _authenticate(api)) return; // user declined the terms
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
                      child: Form(
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
                                'Planka',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to your server',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _serverCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Server URL',
                                  prefixIcon: Icon(Icons.dns_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.url,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.url],
                                validator: (v) =>
                                    (v == null ||
                                        v.trim().isEmpty ||
                                        v.trim() == 'https://')
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Email or username',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
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
                                    ? 'Required'
                                    : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
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
                                    : const Text('Log in'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
