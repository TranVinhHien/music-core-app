import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_item.freezed.dart';

/// A task owned by one Demo account.
@freezed
abstract class TaskItem with _$TaskItem {
  const factory TaskItem({
    required String id,
    required String ownerId,
    required String title,
    required bool isCompleted,
    required DateTime updatedAt,
  }) = _TaskItem;
}
