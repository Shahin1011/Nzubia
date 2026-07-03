import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/bloc/chat/chat_bloc.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/bloc/chat/chat_event.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/bloc/chat/chat_state.dart';
import 'package:customer_nzubia_global/features/messaging/domain/entities/chat_entity.dart';
import 'package:customer_nzubia_global/core/widgets/user_avatar.dart';
import 'package:customer_nzubia_global/core/theme/custom_theme_extension.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(messagingRepository: sl())..add(LoadChats()),
      child: const ChatListView(),
    );
  }
}

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();

    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.supportChatStatus == ChatStatus.loading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
        } else if (state.supportChatStatus == ChatStatus.success && state.supportAdmin != null) {
          Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
          context.push('/chat/${state.supportAdmin!.id}', extra: state.supportAdmin!.fullName ?? 'Support');
        } else if (state.supportChatStatus == ChatStatus.failure) {
          Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Failed to contact support')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Messages', style: TextStyle(color: theme.colorScheme.onSurface)),
          backgroundColor: theme.scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.read<ChatBloc>().add(InitiateSupportChat());
          },
          icon: const Icon(Icons.support_agent),
          label: const Text('Chat with Support'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.chatListStatus == ChatStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.chatListStatus == ChatStatus.failure) {
              return OfflineErrorWidget(
                errorMessage: state.errorMessage ?? 'An error occurred',
                onRetry: () {
                  context.read<ChatBloc>().add(LoadChats());
                },
              );
            }
            if (state.chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Lottie.asset(
                      'assets/animations/receive_order.json',
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                     Text(
                      'No conversations yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chat with agents about your shipments here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: state.chats.length,
              separatorBuilder: (context, index) => Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                return _ChatListItem(chat: chat);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatEntity chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: UserAvatar(
        imageUrl: chat.agentAvatarUrl,
        name: chat.agentName,
        radius: 20,
      ),
      title: Text(
        chat.agentName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(chat.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        context.push('/chat/${chat.agentId}', extra: chat.agentName);
      },
      tileColor: Colors.transparent,
    );
  }
}
