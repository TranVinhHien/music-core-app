import 'demo_account.dart';

/// Public accounts and credentials for the local Demo authentication flow.
final class DemoAccounts {
  DemoAccounts._();

  static const alice = DemoAccount(id: 'alice', email: 'alice@example.com');

  static const bob = DemoAccount(id: 'bob', email: 'bob@example.com');

  static const password = 'demo1234';

  static const all = <DemoAccount>[alice, bob];

  static DemoAccount? byId(String id) {
    for (final account in all) {
      if (account.id == id) return account;
    }
    return null;
  }

  static DemoAccount? byEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in all) {
      if (account.email == normalizedEmail) return account;
    }
    return null;
  }
}
