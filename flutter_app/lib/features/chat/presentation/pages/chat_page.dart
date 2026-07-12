import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:code_card_ai/core/di/injection_container.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../data/models/chat_message_model.dart';
import '../widgets/thinking_block.dart';
import '../widgets/model_selection_widget.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (_) => sl<ChatBloc>()..add(const ChatLoadCatalog()),
      child: const ChatPageView(),
    );
  }
}

class ChatPageView extends StatefulWidget {
  const ChatPageView({super.key});

  @override
  State<ChatPageView> createState() => _ChatPageViewState();
}

class _ChatPageViewState extends State<ChatPageView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(BuildContext context) {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    context.read<ChatBloc>().add(ChatSendMessage(message: text));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatActiveSession) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        // 1. Initial or catalog loading
        if (state is ChatInitial || state is ChatCatalogLoading) {
          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0F0E17)
                : const Color(0xFFF8FAFC),
            body: _buildLoadingState(context, 'Scanning models...'),
          );
        }

        // 2. Model selection catalog
        if (state is ChatCatalogReady) {
          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0F0E17)
                : const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1E1C2A) : Colors.white,
              elevation: 0,
              title: Text(
                'ColdGuard Local AI Setup',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              shape: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF383552)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            body: ModelSelectionWidget(catalogState: state),
          );
        }

        // 3. Model activating status
        if (state is ChatModelActivating) {
          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0F0E17)
                : const Color(0xFFF8FAFC),
            body: _buildLoadingState(
              context,
              'Activating hardware accelerators...',
            ),
          );
        }

        // 4. Conversation session
        if (state is ChatActiveSession) {
          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0F0E17)
                : const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1E1C2A) : Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF383552)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ColdGuard Local AI',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${state.activeModel.name} (${state.activeBackend.name.toUpperCase()})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFA7A9BE)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (state.isTyping)
                  IconButton(
                    icon: Icon(
                      Icons.stop_circle_outlined,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () => context.read<ChatBloc>().add(
                      const ChatStopGeneration(),
                    ),
                    tooltip: 'Stop generation',
                  ),
                IconButton(
                  icon: Icon(
                    Icons.swap_horizontal_circle_outlined,
                    color: theme.primaryColor,
                  ),
                  onPressed: () =>
                      context.read<ChatBloc>().add(const ChatResetSelection()),
                  tooltip: 'Change active model',
                ),
              ],
              shape: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF383552)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
                  if (state.messages.length == 1 && !state.isTyping)
                    _buildSuggestions(context),
                  _buildInputBar(context, state.isTyping),
                ],
              ),
            ),
          );
        }

        // 5. Error status fallback
        if (state is ChatError) {
          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0F0E17)
                : const Color(0xFFF8FAFC),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initialization Failed',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: GoogleFonts.inter(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ChatBloc>().add(const ChatLoadCatalog()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingState(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primaryColor),
          const SizedBox(height: 20),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark
                      ? const Color(0xFF383552)
                      : const Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? primaryColor
                        : (isDark ? const Color(0xFF1E1C2A) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    border: message.isUser
                        ? null
                        : Border.all(
                            color: isDark
                                ? const Color(0xFF383552)
                                : const Color(0xFFE2E8F0),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Render collapsible reasoning block
                      if (message.reasoning != null)
                        ThinkingBlock(
                          thinkingText: message.reasoning!,
                          isComplete: !message.isStreaming,
                        ),
                      // Main Message Content
                      message.isUser
                          ? Text(
                              message.text,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            )
                          : MarkdownBody(
                              data: message.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet.fromTheme(theme)
                                  .copyWith(
                                    p: GoogleFonts.inter(
                                      color: isDark
                                          ? const Color(0xFFFFFFFE)
                                          : const Color(0xFF0F172A),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    strong: GoogleFonts.inter(
                                      color: isDark
                                          ? const Color(0xFFFFFFFE)
                                          : const Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    listBullet: GoogleFonts.inter(
                                      color: isDark
                                          ? const Color(0xFFFFFFFE)
                                          : const Color(0xFF0F172A),
                                      fontSize: 14,
                                    ),
                                  ),
                            ),
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark
                      ? const Color(0xFF383552)
                      : const Color(0xFFE2E8F0),
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: message.isUser ? 0 : 40,
              right: message.isUser ? 40 : 0,
              top: 4,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark
                    ? const Color(0xFFA7A9BE)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final prompts = [
      "How many r's are in strawberry?",
      "Safe storage temp for Hepatitis B?",
      "Explain cold chain excursion impact",
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'Suggested Prompts',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFA7A9BE)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts.map((prompt) {
              return ActionChip(
                backgroundColor: isDark
                    ? const Color(0xFF1E1C2A)
                    : Colors.white,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF383552)
                      : const Color(0xFFE2E8F0),
                ),
                label: Text(
                  prompt,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => context.read<ChatBloc>().add(
                  ChatSendMessage(message: prompt),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isTyping) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C2A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF383552) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F0E17)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF383552)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.keyboard_alt_outlined,
                    color: isDark
                        ? const Color(0xFFA7A9BE)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.primaryColor,
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => _sendMessage(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
