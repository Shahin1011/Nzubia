import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type; // 'SHIPMENT_REQUEST', 'QUOTE_RECEIVED', etc.
  final String relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? relatedEntityId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'related_entity_id': relatedEntityId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'SYSTEM').toString(),
      relatedEntityId: (json['related_entity_id'] ?? json['relatedEntityId'] ?? '').toString(),
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, relatedEntityId, isRead, createdAt];
}
