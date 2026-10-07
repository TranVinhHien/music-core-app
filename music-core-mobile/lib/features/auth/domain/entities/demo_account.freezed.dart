// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'demo_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DemoAccount {
  String get id;
  String get email;

  /// Create a copy of DemoAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DemoAccountCopyWith<DemoAccount> get copyWith =>
      _$DemoAccountCopyWithImpl<DemoAccount>(this as DemoAccount, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as DemoAccount;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DemoAccount &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.email, _this.email) ||
                other.email == _this.email));
  }

  @override
  int get hashCode {
    final _this = this as DemoAccount;
    return Object.hash(runtimeType, _this.id, _this.email);
  }

  @override
  String toString() {
    final _this = this as DemoAccount;
    return 'DemoAccount(id: ${_this.id}, email: ${_this.email})';
  }
}

/// @nodoc
abstract mixin class $DemoAccountCopyWith<$Res> {
  factory $DemoAccountCopyWith(
    DemoAccount value,
    $Res Function(DemoAccount) _then,
  ) = _$DemoAccountCopyWithImpl;
  @useResult
  $Res call({String id, String email});
}

/// @nodoc
class _$DemoAccountCopyWithImpl<$Res> implements $DemoAccountCopyWith<$Res> {
  _$DemoAccountCopyWithImpl(this._self, this._then);

  final DemoAccount _self;
  final $Res Function(DemoAccount) _then;

  /// Create a copy of DemoAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? email = null}) {
    return _then(
      DemoAccount(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _self.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [DemoAccount].
extension DemoAccountPatterns on DemoAccount {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DemoAccount value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DemoAccount() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DemoAccount value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DemoAccount():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DemoAccount value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DemoAccount() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String id, String email)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DemoAccount() when $default != null:
        return $default(_that.id, _that.email);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String id, String email) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DemoAccount():
        return $default(_that.id, _that.email);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String id, String email)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DemoAccount() when $default != null:
        return $default(_that.id, _that.email);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DemoAccount implements DemoAccount {
  const _DemoAccount({required this.id, required this.email});

  @override
  final String id;
  @override
  final String email;

  /// Create a copy of DemoAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DemoAccountCopyWith<_DemoAccount> get copyWith =>
      __$DemoAccountCopyWithImpl<_DemoAccount>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DemoAccount &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, email);
  }

  @override
  String toString() {
    return 'DemoAccount(id: $id, email: $email)';
  }
}

/// @nodoc
abstract mixin class _$DemoAccountCopyWith<$Res>
    implements $DemoAccountCopyWith<$Res> {
  factory _$DemoAccountCopyWith(
    _DemoAccount value,
    $Res Function(_DemoAccount) _then,
  ) = __$DemoAccountCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String email});
}

/// @nodoc
class __$DemoAccountCopyWithImpl<$Res> implements _$DemoAccountCopyWith<$Res> {
  __$DemoAccountCopyWithImpl(this._self, this._then);

  final _DemoAccount _self;
  final $Res Function(_DemoAccount) _then;

  /// Create a copy of DemoAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? id = null, Object? email = null}) {
    return _then(
      _DemoAccount(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _self.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
