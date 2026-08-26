import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/gen/app_localizations.dart';

const privacyPolicyUrl =
    'https://github.com/adambenhassen/planka-app/blob/main/docs/store/privacy-policy.md';

typedef PrivacyPolicyLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

Future<bool> _launchPrivacyPolicy(Uri uri, LaunchMode mode) =>
    launchUrl(uri, mode: mode);

/// Opens the published privacy policy in the system browser.
///
/// The optional launcher keeps this shared action straightforward to exercise
/// without changing the platform URL-launching behavior used in production.
Future<void> openPrivacyPolicy(
  BuildContext context, {
  PrivacyPolicyLauncher? launcher,
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    final opened = await (launcher ?? _launchPrivacyPolicy)(
      Uri.parse(privacyPolicyUrl),
      LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      _showPrivacyPolicyLaunchFailure(context, l10n);
    }
  } catch (error, stackTrace) {
    debugPrint('Privacy policy launch failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      _showPrivacyPolicyLaunchFailure(context, l10n);
    }
  }
}

void _showPrivacyPolicyLaunchFailure(
  BuildContext context,
  AppLocalizations l10n,
) {
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(l10n.privacyPolicyLaunchFailed)));
}

/// A localized, keyboard-accessible secondary action for the shared policy
/// launch behavior.
class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({super.key, this.launcher});

  final PrivacyPolicyLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () => openPrivacyPolicy(context, launcher: launcher),
        icon: const ExcludeSemantics(
          child: Icon(Icons.privacy_tip_outlined, size: 18),
        ),
        label: Text(l10n.privacyPolicy),
      ),
    );
  }
}
