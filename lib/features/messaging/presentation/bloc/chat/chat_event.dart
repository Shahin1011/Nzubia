import 'package:equatable/equatable.dart';
import 'package:customer_nzubia_global/features/messaging/domain/entities/message_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChats extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final String chatId;
  const LoadMessages(this.chatId);
  @override
  List<Object> get props => [chatId];
}

class SendMessage extends ChatEvent {
  final String chatId;
  final String content;
  final String? filePath;
  const SendMessage(this.chatId, this.content, {this.filePath});
  @override
  List<Object?> get props => [chatId, content, filePath];
}

class MessageReceived extends ChatEvent {
  final MessageEntity message;
  const MessageReceived(this.message);
  @override
  List<Object> get props => [message];
}

class MessagesUpdated extends ChatEvent {
  final List<MessageEntity> messages;
  const MessagesUpdated(this.messages);
  @override
  List<Object> get props => [messages];
}

class ConnectWebSocket extends ChatEvent {}
class DisconnectWebSocket extends ChatEvent {}
class InitiateSupportChat extends ChatEvent {}
