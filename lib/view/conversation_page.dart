import 'dart:async';
import 'package:cashier/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class ConversationPage extends StatefulWidget {
  final String conversationId;
  final String userId;

  const ConversationPage({
    super.key,
    required this.conversationId,
    required this.userId,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final NotificationsServices _notificationService = NotificationsServices();
  final supabase = Supabase.instance.client;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Message> messages = [];
  bool isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? subscription;

  @override
  void initState() {
    super.initState();
    _notificationService.initialiseNotification();
    fetchMessages();
    subscribeMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    subscription?.cancel();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true);

    if (!mounted) return;
    setState(() {
      messages = (data as List)
          .map((e) => Message.fromMap(e as Map<String, dynamic>))
          .toList();
      isLoading = false;
    });

    await markMessagesSeen();
    scrollBottom();
  }

  void subscribeMessages() {
  subscription = supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', widget.conversationId)
      .listen((records) async {
    if (!mounted) return;

    final updated = records
        .map((e) => Message.fromMap(e as Map<String, dynamic>))
        .toList();

    // Detect new messages
    final newMessages = updated.where(
      (msg) => !messages.any((m) => m.id == msg.id),
    ).toList();

    if (newMessages.isNotEmpty) {
      setState(() => messages = updated);
      scrollBottom();

      // Mark as seen
      await markMessagesSeen();

      // Show notifications for new messages not from me
      for (var msg in newMessages) {
        if (msg.senderId != widget.userId) {
          await _notificationService.showChatNotification(
            messageId: msg.id,
            content: msg.content,
          );
        }
      }
    }
  });
}

  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    final temp = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: widget.conversationId,
      senderId: widget.userId,
      content: content,
      status: 'sent',
      createdAt: DateTime.now(),
      seen: false,
    );

    setState(() => messages.add(temp));
    scrollBottom();
    messageController.clear();

    try {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': widget.userId,
        'content': content,
        'status': 'sent',
        'seen': false,
      });
    } catch (_) {
      setState(() => messages.removeWhere((m) => m.id == temp.id));
    }
  }

  Future<void> markMessagesSeen() async {
    try {
      await supabase
          .from('messages')
          .update({'seen': true})
          .eq('conversation_id', widget.conversationId)
          .eq('seen', false)
          .neq('sender_id', widget.userId);
    } catch (_) {}
  }

  void scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _onWillPop() async {
    // Mark messages as seen before leaving
    await markMessagesSeen();

    // Return the last message so MessagesPage can update UI
    final lastMsg = messages.isNotEmpty ? messages.last : null;
    Navigator.pop(context, lastMsg);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text("Support Chat")),
        body: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == widget.userId;

                        return Align(
                          alignment:
                              isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (msg.seen)
                                  Text(
                                    "Seen",
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isMe ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}