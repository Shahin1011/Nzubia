import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_entity.dart';
import 'messaging_remote_datasource.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';

class MessagingRemoteDatasourceImpl implements MessagingRemoteDatasource {
  final DioClient dioClient;
  final SocketClient socketClient;

  final _messageStreamController = StreamController<MessageEntity>.broadcast();
  bool _initialized = false; // guard to prevent duplicate listeners

  MessagingRemoteDatasourceImpl(this.dioClient, this.socketClient);

  @override
  Future<void> initialize() async {
    // Only initialize once — prevents duplicate socket listeners if called multiple times
    if (_initialized) {
      // If already initialized but disconnected, reconnect
      if (!socketClient.socket.connected) {
        socketClient.socket.connect();
        if (kDebugMode) debugPrint('🔄 Socket reconnected');
      }
      return;
    }

    await socketClient.init();
    _initialized = true;

    // Remove any existing listener first just in case
    socketClient.socket.off('newMessage');

    socketClient.socket.on('newMessage', (data) {
      if (data != null) {
        try {
          final message = _mapToEntity(Map<String, dynamic>.from(data));
          if (!_messageStreamController.isClosed) {
            _messageStreamController.add(message);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error parsing received message: $e');
        }
      }
    });
    if (kDebugMode) debugPrint('✅ Socket listener registered for receive_message');
  }

  @override
  Stream<MessageEntity> get messageStream => _messageStreamController.stream;

  @override
  void dispose() {
    // NOTE: Do NOT close _messageStreamController or disconnect socket here —
    // this datasource is a singleton shared across the app. Closing it from
    // one screen (chat room) would break real-time for the whole session.
    // The socket remains connected for push notifications even when chat is closed.
    if (kDebugMode) debugPrint('💬 Chat screen closed — keeping socket alive for background messages');
  }

  /// Call this only when completely logging out or terminating the app.
  void fullDispose() {
    socketClient.dispose();
    if (!_messageStreamController.isClosed) {
      _messageStreamController.close();
    }
    _initialized = false;
  }

  @override
  Future<List<ChatEntity>> getChats() async {
    try {
      final response = await dioClient.dio.get('/chat/rooms');
      final data = response.data as List;
      return data.map((e) => _mapToChatEntity(e)).toList();
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  @override
  Future<List<MessageEntity>> getMessages(String chatId) async {
    try {
      final response = await dioClient.dio.get('/chat/rooms/$chatId/messages');
      final data = response.data as List;
      return data.map((e) => _mapToEntity(e)).toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  @override
  Future<void> joinRoom(String roomId) async {
    if (!socketClient.socket.connected) return;
    socketClient.socket.emit('joinRoom', roomId);
  }

  @override
  Future<void> sendMessage(String chatId, String content, {String? filePath}) async {
    try {
      if (filePath != null) {
        // Upload file first, then send message with the returned URL as content
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
        });
        final uploadResp = await dioClient.dio.post('/files/upload', data: formData);
        final fileUrl = uploadResp.data['url'] as String? ?? filePath;
        await dioClient.dio.post('/chat/rooms/$chatId/messages', data: {
          'content': fileUrl,
        });
      } else {
        await dioClient.dio.post('/chat/rooms/$chatId/messages', data: {
          'content': content,
        });
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  MessageEntity _mapToEntity(Map<String, dynamic> data) {
    return MessageEntity(
      id: data['id'] ?? '',
      senderId: data['sender_id'] ?? '',
      receiverId: data['receiver_id'] ?? '',
      content: data['content'] ?? '',
      timestamp: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
      isMe: false, // Calculated by Repository or UI logic
      attachmentUrl: data['attachment_url'],
      attachmentType: data['attachment_type'],
      attachmentName: data['attachment_name'],
    );
  }

  ChatEntity _mapToChatEntity(Map<String, dynamic> data) {
    return ChatEntity(
      id: data['id'] ?? '',
      agentId: data['agent_id'] ?? data['other_user_id'] ?? '',
      agentName: data['agent_name'] ?? data['other_user_name'] ?? 'Agent',
      lastMessage: data['last_message'] ?? '',
      lastMessageTime: DateTime.tryParse(data['last_message_time'] ?? '') ?? DateTime.now(),
      unreadCount: data['unread_count'] ?? 0,
    );
  }

  @override
  Future<Map<String, dynamic>?> getSupportAdmin() async {
    try {
      final response = await dioClient.dio.get('/users/admin/contact');
      return response.data;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching support admin: $e');
      return null;
    }
  }
}
