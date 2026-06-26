import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_datasource.dart';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';
import 'package:customer_nzubia_global/features/auth/data/models/user_model.dart';

@LazySingleton(as: MessagingRepository)
class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteDatasource remoteDatasource;
  final AuthRepository authRepository;
  
  String? _currentUserId;

  MessagingRepositoryImpl({
    required this.remoteDatasource,
    required this.authRepository,
  });

  @override
  Stream<MessageEntity> get messageStream {
    return remoteDatasource.messageStream.asyncMap((message) async {
      if (_currentUserId == null) {
        await _ensureAuth();
      }
      return message.copyWith(isMe: message.senderId == _currentUserId);
    });
  }
  // No need for empty stream method body here.

  Future<void> _ensureAuth() async {
    final user = await authRepository.getCurrentUser();
    _currentUserId = user?.id;
  }

  @override
  Future<void> initialize() async {
    await _ensureAuth();
    await remoteDatasource.initialize();
    if (kDebugMode) debugPrint('✅ WebSocket Messaging Repository Initialized for User: $_currentUserId');
  }

  @override
  Future<void> joinRoom(String roomId) async {
    await remoteDatasource.joinRoom(roomId);
  }

  @override
  Future<List<ChatEntity>> getChats() async {
    await _ensureAuth();
    if (_currentUserId == null) return [];

    try {
      final chats = await remoteDatasource.getChats();
      // Sort client-side by lastMessageTime (descending)
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching chats: $e');
      return [];
    }
  }

  @override
  Future<List<MessageEntity>> getMessages(String chatId) async {
      await _ensureAuth();
      if (_currentUserId == null) return [];
      
      try {
        final messages = await remoteDatasource.getMessages(chatId);
        // Mark as "me" if sender matches
        return messages.map((m) => m.copyWith(isMe: m.senderId == _currentUserId)).toList();
      } catch (e) {
          if (kDebugMode) debugPrint('Error fetching messages: $e');
          return [];
      }
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String chatId) {
      // The Socket backend currently only streams individual messages.
      // To simulate a full list stream, we would normally maintain state here or in Bloc.
      // Since ChatBloc handles adding new messages from the single `messageStream`, 
      // providing the initial list as a 1-item stream is sufficient to seed the UI.
      return Stream.fromFuture(getMessages(chatId));
  }

  @override
  Future<void> sendMessage(String receiverId, String content, {String? filePath}) async {
    await _ensureAuth();
    if (_currentUserId == null) return;

    try {
        await remoteDatasource.sendMessage(receiverId, content, filePath: filePath);
    } catch (e) {
        if (kDebugMode) debugPrint('Error sending message: $e');
        rethrow;
    }
  }

  @override
  Future<UserEntity?> getSupportAdmin() async {
    try {
      final data = await remoteDatasource.getSupportAdmin();
      if (data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    remoteDatasource.dispose();
  }
}
