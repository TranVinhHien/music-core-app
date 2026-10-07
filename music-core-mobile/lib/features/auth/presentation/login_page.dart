import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../domain/entities/demo_accounts.dart';
import 'auth_controller.dart';
import 'auth_failure_message.dart';
import 'auth_widget_keys.dart';

/// Signs in to one of the public local Demo accounts.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = appLocalizationsOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.loginTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localizations.loginSubtitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: AuthWidgetKeys.loginEmail,
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: localizations.emailLabel,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? localizations.emailRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: AuthWidgetKeys.loginPassword,
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: localizations.passwordLabel,
                    ),
                    obscureText: true,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) => value == null || value.isEmpty
                        ? localizations.passwordRequired
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _LoginButton(
                    localizations: localizations,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.demoCredentials,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${DemoAccounts.alice.email} / ${DemoAccounts.password}',
                          ),
                          Text(
                            '${DemoAccounts.bob.email} / ${DemoAccounts.password}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (ref.read(authControllerProvider).isLoading) return;
    final formState = _formKey.currentState;
    if (formState?.validate() != true) return;
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text, _passwordController.text);
    if (!mounted || failure == null) return;
    final localizations = appLocalizationsOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authFailureMessage(failure, localizations))),
    );
  }
}

class _LoginButton extends ConsumerWidget {
  const _LoginButton({required this.localizations, required this.onPressed});

  final AppLocalizations localizations;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      authControllerProvider.select((state) => state.isLoading),
    );

    return FilledButton(
      key: AuthWidgetKeys.loginButton,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(localizations.loginButton),
    );
  }
}
