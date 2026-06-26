import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/messaging/domain/entities/chat_entity.dart';
import 'package:customer_nzubia_global/features/messaging/domain/entities/message_entity.dart';
import 'package:customer_nzubia_global/features/messaging/domain/repositories/messaging_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

import 'dart:async'; // Add import

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessagingRepository _messagingRepository;
  late StreamSubscription<MessageEntity> _messageSubscription; 
  StreamSubscription<List<MessageEntity>>? _chatMessagesSubscription; // Dedicated subscription for list updates

  ChatBloc({required MessagingRepository messagingRepository})
      : _messagingRepository = messagingRepository,
        super(const ChatState()) {
    on<LoadChats>(_onLoadChats);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived); 
    on<MessagesUpdated>(_onMessagesUpdated); // New event handler

    // Listen to repository stream
    _messageSubscription = _messagingRepository.messageStream.listen((message) {
      add(MessageReceived(message));
    });

    on<ConnectWebSocket>((event, emit) async {
      // initialize() is idempotent — safe to call multiple times
      await _messagingRepository.initialize();
    });

    on<DisconnectWebSocket>((event, emit) async {
      // Do NOT call _messagingRepository.dispose() here!
      // The MessagingRemoteDatasource is a singleton — disposing it from one
      // chat screen would break real-time messages for the entire app session.
      // The socket stays connected to receive messages in the background.
      await _chatMessagesSubscription?.cancel();
      _chatMessagesSubscription = null;
    });

    on<InitiateSupportChat>(_onInitiateSupportChat);
  }

  @override
  Future<void> close() {
    _messageSubscription.cancel();
    _chatMessagesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadChats(LoadChats event, Emitter<ChatState> emit) async {
    emit(state.copyWith(chatListStatus: ChatStatus.loading));
    try {
      final chats = await _messagingRepository.getChats();
      emit(state.copyWith(chatListStatus: ChatStatus.success, chats: chats));
    } catch (e) {
      emit(state.copyWith(
        chatListStatus: ChatStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(state.copyWith(messageStatus: ChatStatus.loading));

    // Cancel previous stream subscription for messages if any
    await _chatMessagesSubscription?.cancel();

    // Join the socket room so real-time messages are received
    await _messagingRepository.joinRoom(event.chatId);

    try {
      _chatMessagesSubscription = _messagingRepository.getMessagesStream(event.chatId).listen((messages) {
         add(MessagesUpdated(messages));
      });
    } catch (e) {
      emit(state.copyWith(
        messageStatus: ChatStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  // Add new handler
  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
      emit(state.copyWith(messageStatus: ChatStatus.success, messages: event.messages));
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    try {
      await _messagingRepository.sendMessage(event.chatId, event.content, filePath: event.filePath);
      // We rely completely on the socket's `MessageReceived` event to append the message to the UI.
      // This prevents duplicate messages appearing when sending.
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to send: ${e.toString()}'
      ));
    }
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    final updatedMessages = List<MessageEntity>.from(state.messages)..add(event.message);
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _onInitiateSupportChat(InitiateSupportChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(supportChatStatus: ChatStatus.loading));
    try {
      final admin = await _messagingRepository.getSupportAdmin();
      if (admin != null) {
        emit(state.copyWith(supportChatStatus: ChatStatus.success, supportAdmin: admin));
        // Reset status after success so it doesn't trigger again on rebuilds
        emit(state.copyWith(supportChatStatus: ChatStatus.initial));
      } else {
        emit(state.copyWith(
          supportChatStatus: ChatStatus.failure,
          errorMessage: 'Support admin not found',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        supportChatStatus: ChatStatus.failure,
        errorMessage: 'Failed to initiate support chat: $e',
      ));
    }
  }
}
