import 'package:meta/meta.dart';

@immutable
class EventSourceModel {
  const EventSourceModel({
    required this.type,
    this.id,
  });

  final String type;
  final String? id;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (id != null) 'id': id,
    };
  }

  factory EventSourceModel.fromJson(Map<String, dynamic> json) {
    return EventSourceModel(
      type: json['type'] as String? ?? 'unknown',
      id: json['id'] as String?,
    );
  }
}

@immutable
class ClientEvent {
  const ClientEvent({
    required this.eventId,
    required this.eventType,
    required this.occurredAt,
    this.sessionId,
    this.trackId,
    this.source,
    this.properties = const {},
    this.schemaVersion = 1,
  });

  final String eventId;
  final String eventType;
  final DateTime occurredAt;
  final String? sessionId;
  final String? trackId;
  final EventSourceModel? source;
  final Map<String, dynamic> properties;
  final int schemaVersion;

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_type': eventType,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'schema_version': schemaVersion,
      if (sessionId != null) 'session_id': sessionId,
      if (trackId != null) 'track_id': trackId,
      if (source != null) 'source': source!.toJson(),
      'properties': properties,
    };
  }
}
