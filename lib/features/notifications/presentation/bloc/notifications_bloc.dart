import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:customer_nzubia_global/features/notifications/domain/entities/notification_entity.dart';

// Events
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

class MarkNotificationAsRead extends NotificationsEvent {
  final String id;
  const MarkNotificationAsRead(this.id);
  @override
  List<Object> get props => [id];
}

// State
enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationEntity> notifications;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationEntity>? notifications,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}

// Bloc
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  static const String _boxKey = 'settings';
  static const String _notificationsStorageKey = 'app_user_notifications';
  static const String _readIdsStorageKey = 'read_notification_ids';

  NotificationsBloc() : super(const NotificationsState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
  }

  Box? _getBox() {
    if (Hive.isBoxOpen(_boxKey)) {
      return Hive.box(_boxKey);
    }
    return null;
  }

  Set<String> _getReadIds() {
    final box = _getBox();
    if (box != null) {
      final list = box.get(_readIdsStorageKey);
      if (list is List) {
        return list.map((e) => e.toString()).toSet();
      }
    }
    return {};
  }

  Future<void> _saveReadId(String id) async {
    final box = _getBox();
    if (box != null) {
      final ids = _getReadIds()..add(id);
      await box.put(_readIdsStorageKey, ids.toList());
    }
  }

  static Future<void> savePushNotification({
    required String title,
    required String message,
    String type = 'SYSTEM',
    String relatedEntityId = '',
  }) async {
    try {
      if (Hive.isBoxOpen(_boxKey)) {
        final box = Hive.box(_boxKey);
        final storedData = box.get(_notificationsStorageKey);
        final list = storedData is List ? List<dynamic>.from(storedData) : <dynamic>[];
        final newNotif = NotificationEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          message: message,
          type: type,
          relatedEntityId: relatedEntityId,
          isRead: false,
          createdAt: DateTime.now(),
        );
        list.insert(0, newNotif.toJson());
        await box.put(_notificationsStorageKey, list);
      }
    } catch (_) {}
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      final box = _getBox();
      final readIds = _getReadIds();

      List<NotificationEntity> notifs = [];

      final storedData = box?.get(_notificationsStorageKey);
      if (storedData is List && storedData.isNotEmpty) {
        for (final item in storedData) {
          if (item is Map) {
            final entity = NotificationEntity.fromJson(Map<String, dynamic>.from(item));
            notifs.add(entity.copyWith(
              isRead: entity.isRead || readIds.contains(entity.id),
            ));
          }
        }
      }

      // If storage is empty (first time opening notifications):
      if (notifs.isEmpty) {
        final now = DateTime.now();
        notifs = [
          NotificationEntity(
            id: '1',
            title: 'New Shipment Request',
            message: 'Shipment #S-12345 matches your profile.',
            type: 'SHIPMENT_REQUEST',
            relatedEntityId: 'uuid-shipment-123',
            isRead: readIds.contains('1'),
            createdAt: now.subtract(const Duration(minutes: 5)),
          ),
          NotificationEntity(
            id: '2',
            title: 'Welcome',
            message: 'Welcome to Nzubia.',
            type: 'SYSTEM',
            relatedEntityId: '',
            isRead: true,
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ];

        // Persist to box with fixed createdAt timestamps so they are NEVER recomputed on refresh!
        if (box != null) {
          await box.put(
            _notificationsStorageKey,
            notifs.map((n) => n.toJson()).toList(),
          );
        }
      }

      emit(state.copyWith(
        status: NotificationsStatus.success,
        notifications: notifs,
      ));
    } catch (e) {
      emit(state.copyWith(status: NotificationsStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onMarkNotificationAsRead(MarkNotificationAsRead event, Emitter<NotificationsState> emit) async {
    await _saveReadId(event.id);

    final box = _getBox();
    final updatedList = state.notifications.map((n) {
      if (n.id == event.id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    if (box != null) {
      await box.put(
        _notificationsStorageKey,
        updatedList.map((n) => n.toJson()).toList(),
      );
    }

    emit(state.copyWith(notifications: updatedList));
  }
}
