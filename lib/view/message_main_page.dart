import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import 'conversation_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final supabase = Supabase.instance.client;

  String userId = "";
  String userName = "User";
  bool isAdmin = false;
  bool isLoading = true;

  List<Conversation> conversations = [];
  Map<String, Message?> lastMessages = {};
  Map<String, int> unreadCount = {};
  Map<String, String> userNames = {};

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    userId = user.id;

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    userName = profile?['full_name'] ?? "User";
    isAdmin = profile?['role'] == 'admin';

    await fetchConversations();
    listenRealtimeUpdates();
  }

  Future<void> fetchConversations() async {
    setState(() => isLoading = true);

    List data;

    if (isAdmin) {
      data = await supabase
          .from('conversations')
          .select()
          .order('created_at', ascending: false);
    } else {
      final member = await supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', userId);

      final ids = (member as List).map((e) => e['conversation_id']).toList();
      if (ids.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      data = await supabase
          .from('conversations')
          .select()
          .inFilter('id', ids)
          .order('created_at', ascending: false);
    }

    conversations = (data as List)
        .map((e) => Conversation.fromMap(e as Map<String, dynamic>))
        .toList();

    for (var conv in conversations) {
      lastMessages[conv.id] = null;
      unreadCount[conv.id] = 0;
      if (isAdmin) userNames[conv.id] = "User";
    }

    setState(() => isLoading = false);
  }

  Future<void> loadConversationData(String convId) async {
    final lastMsg = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', convId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    lastMessages[convId] = lastMsg != null ? Message.fromMap(lastMsg) : null;

    final unreadMsgs = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', convId)
        .eq('seen', false)
        .neq('sender_id', userId);

    unreadCount[convId] = (unreadMsgs as List).length;

    if (isAdmin) {
      final member = await supabase
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', convId)
          .neq('user_id', userId)
          .maybeSingle();

      if (member != null) {
        final profile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', member['user_id'])
            .maybeSingle();

        if (profile != null) userNames[convId] = profile['full_name'];
      }
    }

    setState(() {});
  }

  void listenRealtimeUpdates() {
    supabase.from('messages').stream(primaryKey: ['id']).listen((event) {
      for (var row in event) {
        final msg = Message.fromMap(row as Map<String, dynamic>);
        if (lastMessages.containsKey(msg.conversationId)) {
          lastMessages[msg.conversationId] = msg;

          if (msg.senderId != userId) {
            unreadCount[msg.conversationId] =
                (unreadCount[msg.conversationId] ?? 0) + 1;
          }

          setState(() {});
        }
      }
    });
  }

  Future<void> startConversation() async {
    final existing = await supabase
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', userId)
        .maybeSingle();

    String convId;

    if (existing == null) {
      final newConv = await supabase
          .from('conversations')
          .insert({'title': 'Support'})
          .select()
          .single();

      convId = newConv['id'];

      await supabase.from('conversation_members').insert({
        'conversation_id': convId,
        'user_id': userId,
      });
    } else {
      convId = existing['conversation_id'];
    }

    final result = await Navigator.push<Message>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ConversationPage(conversationId: convId, userId: userId),
      ),
    );

    if (result != null) {
      lastMessages[convId] = result;
      unreadCount[convId] = 0;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text("Messages")),
      body: Column(
        children: [
          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Contact Support"),
              onTap: startConversation,
            ),
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final last = lastMessages[conv.id];
                final unread = unreadCount[conv.id] ?? 0;

                return Card(
                  child: ListTile(
                    title: Text(
                      isAdmin ? (userNames[conv.id] ?? "User") : "Support",
                    ),
                    subtitle: Text(
                      last != null
                          ? (last.senderId == userId
                                ? "You: ${last.content}"
                                : last.content)
                          : "No messages yet",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: (last != null && last.senderId != userId)
                            ? FontWeight
                                  .bold // gikan sa other user -> bold
                            : FontWeight.normal, // gikan nimo -> normal
                      ),
                    ),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      await loadConversationData(conv.id);

                      final result = await Navigator.push<Message>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversationPage(
                            conversationId: conv.id,
                            userId: userId,
                          ),
                        ),
                      );

                      if (result != null) {
                        lastMessages[conv.id] = result;
                        unreadCount[conv.id] = 0; // reset after seen
                        setState(() {});
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
