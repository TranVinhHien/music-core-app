import 'package:flutter/widgets.dart';

/// Stable widget keys owned by the authentication presentation layer.
abstract final class AuthWidgetKeys {
  static const loginEmail = Key('login_email');
  static const loginPassword = Key('login_password');
  static const loginButton = Key('login_button');
}
