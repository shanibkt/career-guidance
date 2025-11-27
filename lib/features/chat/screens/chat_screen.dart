import 'package:flutter/material.dart';
import '../../../services/api/chat_service.dart';
import '../../../services/api/chat_history_service.dart';
import '../../../services/local/storage_service.dart';

// Chat Page
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<ChatSession> _chatHistory = [];
  String? _currentSessionId;
  bool _useServerSync = true; // Toggle for server sync

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _loadChatHistory() async {
    print('📂 Loading chat history...');

    if (_useServerSync) {
      // Try to load from server first
      final serverSessions = await ChatHistoryService.getSessions();
      if (serverSessions != null && serverSessions.isNotEmpty) {
        print('✅ Loaded ${serverSessions.length} sessions from server');
        setState(() {
          _chatHistory = serverSessions.map((s) {
            return ChatSession(
              id: s['sessionId'] as String,
              title: s['title'] as String,
              lastMessage: s['lastMessage'] as String? ?? '',
              timestamp: DateTime.parse(s['updatedAt'] as String),
            );
          }).toList();
        });
        print('✅ Updated UI with ${_chatHistory.length} sessions');
        // Also save to local storage as cache
        await _saveChatHistory();
        return;
      } else {
        print('⚠️ No sessions from server, trying local storage');
      }
    }

    // Fallback to local storage
    final sessions = await StorageService.loadChatHistory();
    print('📦 Loaded ${sessions.length} sessions from local storage');
    setState(() {
      _chatHistory = sessions.map((s) => ChatSession.fromJson(s)).toList();
    });
    print('✅ Updated UI with ${_chatHistory.length} sessions');
  }

  Future<void> _saveChatHistory() async {
    final sessions = _chatHistory.map((s) => s.toJson()).toList();
    await StorageService.saveChatHistory(sessions);
  }

  Future<void> _saveCurrentSession() async {
    if (_messages.isEmpty || _currentSessionId == null) {
      print('⚠️ Cannot save: messages empty or no session ID');
      return;
    }

    print(
      '💾 Saving session: $_currentSessionId with ${_messages.length} messages',
    );

    // Generate session title from first user message
    final firstUserMessage = _messages.firstWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(
        text: 'New Conversation',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    final title = firstUserMessage.text.length > 30
        ? '${firstUserMessage.text.substring(0, 30)}...'
        : firstUserMessage.text;

    final lastMessage = _messages.isNotEmpty ? _messages.last.text : '';
    final lastMessagePreview = lastMessage.length > 50
        ? '${lastMessage.substring(0, 50)}...'
        : lastMessage;

    print('📝 Session title: $title');
    print('📝 Last message: $lastMessagePreview');

    // Save to server if enabled
    if (_useServerSync) {
      final saved = await ChatHistoryService.saveSession(
        sessionId: _currentSessionId!,
        title: title,
        lastMessage: lastMessagePreview,
      );
      print('🌐 Server save result: $saved');
    }

    // Check if session already exists
    final existingIndex = _chatHistory.indexWhere(
      (s) => s.id == _currentSessionId,
    );

    if (existingIndex >= 0) {
      // Update existing session
      _chatHistory[existingIndex] = ChatSession(
        id: _currentSessionId!,
        title: title,
        lastMessage: lastMessagePreview,
        timestamp: DateTime.now(),
      );
      print('✅ Updated existing session at index $existingIndex');
    } else {
      // Add new session at the beginning
      _chatHistory.insert(
        0,
        ChatSession(
          id: _currentSessionId!,
          title: title,
          lastMessage: lastMessagePreview,
          timestamp: DateTime.now(),
        ),
      );
      print('✅ Added new session to history');
    }

    // Save messages for this session (local cache)
    final messagesJson = _messages.map((m) => m.toJson()).toList();
    await StorageService.saveChatMessages(_currentSessionId!, messagesJson);
    print('✅ Saved ${messagesJson.length} messages to local storage');

    // Save chat history (local cache)
    await _saveChatHistory();
    print('✅ Chat session saved successfully');
  }

  Future<void> _loadChatSession(String sessionId) async {
    print('📂 Loading chat session: $sessionId');

    if (_useServerSync) {
      // Try loading from server first
      final serverMessages = await ChatHistoryService.getSessionMessages(
        sessionId,
      );
      if (serverMessages != null && serverMessages.isNotEmpty) {
        print('✅ Loaded ${serverMessages.length} messages from server');
        setState(() {
          _currentSessionId = sessionId;
          _messages.clear();
          _messages.addAll(
            serverMessages.map((m) {
              return ChatMessage(
                text: m['message'] as String,
                isUser: m['isUser'] as bool,
                timestamp: DateTime.parse(m['timestamp'] as String),
              );
            }),
          );
        });
        print('✅ Updated UI with ${_messages.length} messages');
        _scrollToBottom();
        return;
      } else {
        print('⚠️ No messages from server, trying local storage');
      }
    }

    // Fallback to local storage
    final messagesJson = await StorageService.loadChatMessages(sessionId);
    print('📦 Loaded ${messagesJson.length} messages from local storage');

    if (messagesJson.isEmpty) {
      print('❌ No messages found for session $sessionId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No messages found in this chat'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      _currentSessionId = sessionId;
      _messages.clear();
      _messages.addAll(messagesJson.map((m) => ChatMessage.fromJson(m)));
    });
    print('✅ Updated UI with ${_messages.length} messages');
    _scrollToBottom();
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    });
    ChatService.startNewSession();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();

    // Auto-scroll to bottom
    _scrollToBottom();

    try {
      // Send message to AI backend
      final aiResponse = await ChatService.sendMessage(text);

      if (!mounted) return;

      if (aiResponse != null) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });

        // Save chat session after successful response
        await _saveCurrentSession();
      } else {
        throw Exception('No response from AI');
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      print('🚨 Chat screen error: $errorMessage');

      // Check if it's a backend AI configuration error
      final isBackendAIError =
          errorMessage.contains('Backend error') ||
          errorMessage.contains('Server error') ||
          errorMessage.contains('500');

      setState(() {
        _messages.add(
          ChatMessage(
            text: isBackendAIError
                ? '⚠️ AI Assistant Temporarily Unavailable\n\n'
                      'The backend AI service (Groq API) needs configuration.\n\n'
                      '💡 For your backend developer:\n'
                      '• Check Groq API key is valid\n'
                      '• Verify API endpoint is working\n'
                      '• Check backend console logs\n\n'
                      'Meanwhile, you can explore other app features!'
                : '❌ $errorMessage\n\nPlease try again or start a new chat.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBackendAIError
                ? 'AI service unavailable - backend configuration needed'
                : errorMessage,
          ),
          backgroundColor: isBackendAIError
              ? Colors.orange.shade700
              : Colors.red.shade700,
          duration: const Duration(seconds: 5),
          action: isBackendAIError
              ? null
              : SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    _messageController.text = text;
                    _sendMessage();
                  },
                ),
        ),
      );
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        title: const Text('AI Career Assistant'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _startNewChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New conversation started')),
              );
            },
            tooltip: 'New Chat',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.chat, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your conversations',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _chatHistory.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No chat history yet.\nStart a conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final session = _chatHistory[index];
                        return Dismissible(
                          key: Key(session.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) async {
                            final deletedSession = session;

                            // Delete from server if enabled
                            if (_useServerSync) {
                              await ChatHistoryService.deleteSession(
                                session.id,
                              );
                            }

                            // Delete from local storage
                            await StorageService.deleteChatSession(session.id);

                            setState(() {
                              _chatHistory.removeAt(index);
                            });

                            await _saveChatHistory();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted: ${session.title}'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    setState(() {
                                      _chatHistory.insert(
                                        index,
                                        deletedSession,
                                      );
                                    });
                                    await _saveChatHistory();
                                    // Note: Cannot undo server deletion
                                  },
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                            ),
                            title: Text(
                              session.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              session.lastMessage,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatTimestamp(session.timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black38,
                              ),
                            ),
                            onTap: () async {
                              Navigator.pop(context);

                              // Show loading indicator
                              setState(() {
                                _isLoading = true;
                              });

                              await _loadChatSession(session.id);

                              setState(() {
                                _isLoading = false;
                              });

                              if (_messages.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'No messages found in "${session.title}"',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Loaded: ${session.title} (${_messages.length} messages)',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Clear History',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All History?'),
                    content: const Text(
                      'This will delete all chat conversations. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                Navigator.pop(context);

                if (_useServerSync) {
                  // Clear from server
                  final result = await ChatHistoryService.clearAllHistory();
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted ${result['deletedSessions']} chats with ${result['deletedMessages']} messages',
                        ),
                      ),
                    );
                  }
                }

                // Clear local storage
                await StorageService.clearChatHistory();
                setState(() {
                  _chatHistory.clear();
                });
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 100,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Ask me about careers, skills, or educational paths!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text input field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                      tooltip: 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.psychology, size: 18, color: Colors.blue[700]),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF2196F3) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : Radius.zero,
                  bottomRight: message.isUser
                      ? Radius.zero
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.psychology, size: 18, color: Colors.blue[700]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animatedValue = ((value - delay) * 2).clamp(0.0, 1.0);
        final opacity = (animatedValue * 2 - 1).abs();

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue[700]!.withOpacity(0.3 + opacity * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted && _isLoading) {
          setState(() {}); // Restart animation
        }
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lastMessage': lastMessage,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    title: json['title'] as String,
    lastMessage: json['lastMessage'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
