// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskItem {
  String get id;
  String get ownerId;
  String get title;
  bool get isCompleted;
  DateTime get updatedAt;

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TaskItemCopyWith<TaskItem> get copyWith =>
      _$TaskItemCopyWithImpl<TaskItem>(this as TaskItem, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as TaskItem;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TaskItem &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.ownerId, _this.ownerId) ||
                other.ownerId == _this.ownerId) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.isCompleted, _this.isCompleted) ||
                other.isCompleted == _this.isCompleted) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @override
  int get hashCode {
    final _this = this as TaskItem;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.ownerId,
      _this.title,
      _this.isCompleted,
      _this.updatedAt,
    );
  }

  @override
  String toString() {
    final _this = this as TaskItem;
    return 'TaskItem(id: ${_this.id}, ownerId: ${_this.ownerId}, title: ${_this.title}, isCompleted: ${_this.isCompleted}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $TaskItemCopyWith<$Res> {
  factory $TaskItemCopyWith(TaskItem value, $Res Function(TaskItem) _then) =
      _$TaskItemCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String ownerId,
    String title,
    bool isCompleted,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$TaskItemCopyWithImpl<$Res> implements $TaskItemCopyWith<$Res> {
  _$TaskItemCopyWithImpl(this._self, this._then);

  final TaskItem _self;
  final $Res Function(TaskItem) _then;

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? isCompleted = null,
    Object? updatedAt = null,
  }) {
    return _then(
      TaskItem(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _self.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        isCompleted: null == isCompleted
            ? _self.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        updatedAt: null == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [TaskItem].
extension TaskItemPatterns on TaskItem {
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
    TResult Function(_TaskItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaskItem() when $default != null:
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
    TResult Function(_TaskItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskItem():
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
    TResult? Function(_TaskItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskItem() when $default != null:
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
    TResult Function(
      String id,
      String ownerId,
      String title,
      bool isCompleted,
      DateTime updatedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaskItem() when $default != null:
        return $default(
          _that.id,
          _that.ownerId,
          _that.title,
          _that.isCompleted,
          _that.updatedAt,
        );
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
    TResult Function(
      String id,
      String ownerId,
      String title,
      bool isCompleted,
      DateTime updatedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskItem():
        return $default(
          _that.id,
          _that.ownerId,
          _that.title,
          _that.isCompleted,
          _that.updatedAt,
        );
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
    TResult? Function(
      String id,
      String ownerId,
      String title,
      bool isCompleted,
      DateTime updatedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskItem() when $default != null:
        return $default(
          _that.id,
          _that.ownerId,
          _that.title,
          _that.isCompleted,
          _that.updatedAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TaskItem implements TaskItem {
  const _TaskItem({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.isCompleted,
    required this.updatedAt,
  });

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String title;
  @override
  final bool isCompleted;
  @override
  final DateTime updatedAt;

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TaskItemCopyWith<_TaskItem> get copyWith =>
      __$TaskItemCopyWithImpl<_TaskItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TaskItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, ownerId, title, isCompleted, updatedAt);
  }

  @override
  String toString() {
    return 'TaskItem(id: $id, ownerId: $ownerId, title: $title, isCompleted: $isCompleted, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$TaskItemCopyWith<$Res>
    implements $TaskItemCopyWith<$Res> {
  factory _$TaskItemCopyWith(_TaskItem value, $Res Function(_TaskItem) _then) =
      __$TaskItemCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String ownerId,
    String title,
    bool isCompleted,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$TaskItemCopyWithImpl<$Res> implements _$TaskItemCopyWith<$Res> {
  __$TaskItemCopyWithImpl(this._self, this._then);

  final _TaskItem _self;
  final $Res Function(_TaskItem) _then;

  /// Create a copy of TaskItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? title = null,
    Object? isCompleted = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _TaskItem(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _self.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        isCompleted: null == isCompleted
            ? _self.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        updatedAt: null == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}
