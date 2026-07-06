import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/planka_api.dart';
import '../auth/accounts.dart';
import '../auth/auth_providers.dart';

/// Factory so tests can inject a fake API.
final apiFactoryProvider =
    Provider<PlankaApi Function(String serverUrl)>((ref) => (url) => PlankaApi(url, null));

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

  @override
  void dispose() {
    _serverCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final serverUrl = _serverCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      final api = ref.read(apiFactoryProvider)(serverUrl);
      await api.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      final me = await api.get('/users/me');
      final account = Account(
        serverUrl: serverUrl,
        token: api.token!,
        userId: me.item['id'] as String,
        displayName: (me.item['name'] ?? me.item['username'] ?? '') as String,
      );
      await ref.read(accountsProvider.notifier).upsert(account);
      await ref.read(currentAccountProvider.notifier).select(account);
      if (mounted) context.go('/projects');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.statusCode == 401 ? 'Invalid credentials' : e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Planka',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _serverCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Server URL', border: OutlineInputBorder()),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty || v.trim() == 'https://')
                            ? 'Required'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Email or username',
                        border: OutlineInputBorder()),
                    autocorrect: false,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Password', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
