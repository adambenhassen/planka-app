import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/gen/app_localizations.dart';

const privacyPolicyUrl =
    'https://github.com/adambenhassen/planka-app/blob/main/docs/store/privacy-policy.md';

typedef PrivacyPolicyLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

Future<bool> _launchPrivacyPolicy(Uri uri, LaunchMode mode) =>
    launchUrl(uri, mode: mode);

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
  } catch (error) {
    debugPrint('privacy policy launch failed: $error');
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
