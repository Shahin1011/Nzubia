import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../domain/entities/message_entity.dart';
import '../bloc/chat/chat_bloc.dart';
import '../bloc/chat/chat_event.dart';
import '../bloc/chat/chat_state.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String agentName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.agentName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatBloc _chatBloc; // Store reference to avoid dispose error
  File? _selectedFile;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(ConnectWebSocket());
    _chatBloc.add(LoadMessages(widget.chatId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.add(DisconnectWebSocket()); // Use stored reference instead of context.read
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedFile == null) return;

    context.read<ChatBloc>().add(SendMessage(
      widget.chatId, 
      content.isEmpty ? 'Attachment' : content,
      filePath: _selectedFile?.path,
    ));
    _messageController.clear();
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.agentName, style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
            onPressed: () {
              context.read<ChatBloc>().add(LoadMessages(widget.chatId));
            },
          ),
        ],
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listenWhen: (previous, current) => previous.messages.length != current.messages.length,
        listener: (context, state) {
          // Auto-scroll to bottom when new messages arrive
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        child: Column(
          children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.messageStatus == ChatStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.messageStatus == ChatStatus.failure) {
                  return OfflineErrorWidget(
                    errorMessage: state.errorMessage ?? 'An error occurred',
                    onRetry: () {
                      context.read<ChatBloc>().add(LoadMessages(widget.chatId));
                    },
                  );
                }

                final messages = state.messages;

                if (state.messageStatus == ChatStatus.success && messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54)),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isOwn: message.isMe,
                      otherName: widget.agentName,
                    );
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedFile != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFileName ?? 'File',
                              style: TextStyle(color: theme.colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: theme.colorScheme.error, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _selectedFileName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.attach_file, color: theme.colorScheme.primary),
                        onPressed: _pickFile,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: IconButton(
                          icon: Icon(Icons.send, color: theme.colorScheme.onPrimary),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isOwn;
  final String otherName;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bubbleColor = isOwn
        ? AppTheme.primaryColor
        : (theme.brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFEEEEEE));

    final textColor = isOwn ? Colors.white : theme.colorScheme.onSurface;
    final timeColor = isOwn
        ? Colors.white.withValues(alpha: 0.7)
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOwn ? 18 : 4),
      bottomRight: Radius.circular(isOwn ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isOwn)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                otherName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOwn) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.attachmentUrl != null)
                        ..._buildAttachment(message, theme, context, textColor),
                      if (message.content.isNotEmpty)
                        Text(
                          message.content,
                          style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
                        ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(child: const SizedBox()),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(color: timeColor, fontSize: 10),
                          ),
                          if (isOwn) ...[
                            const SizedBox(width: 3),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 13,
                              color: timeColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isOwn) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<Widget> _buildAttachment(
    MessageEntity message,
    ThemeData theme,
    BuildContext context,
    Color textColor,
  ) {
    final isImage = message.attachmentType?.startsWith('image/') ?? false;

    if (isImage && message.attachmentUrl != null) {
      return [
        GestureDetector(
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.9),
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              transitionDuration: const Duration(milliseconds: 250),
              pageBuilder: (context, _, __) => SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(message.attachmentUrl!, fit: BoxFit.contain),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              message.attachmentUrl!,
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: textColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text('Image unavailable', style: TextStyle(color: textColor.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ];
    } else {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: textColor.withValues(alpha: 0.85), size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message.attachmentName ?? 'File',
                  style: TextStyle(color: textColor, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ];
    }
  }
}
