import 'package:freezed_annotation/freezed_annotation.dart';

part 'demo_account.freezed.dart';

/// A public account used by the deterministic local Demo authentication flow.
@freezed
abstract class DemoAccount with _$DemoAccount {
  const factory DemoAccount({required String id, required String email}) =
      _DemoAccount;
}
