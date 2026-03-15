// widgets/support_button.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../view/message_main_page.dart';

class SupportButton extends StatefulWidget {
  const SupportButton({super.key});

  @override
  State<SupportButton> createState() => _SupportButtonState();
}

class _SupportButtonState extends State<SupportButton> {
  final supabase = Supabase.instance.client;
  int unread = 0;
  String userId = "";
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> initUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    userId = user.id;

    await fetchUnread();
    subscription = supabase.from('messages').stream(primaryKey: ['id']).listen((_) {
      fetchUnread();
    });
  }

  Future<void> fetchUnread() async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('seen', false)
        .neq('sender_id', userId);

    if (!mounted) return;
    setState(() {
      unread = (data as List).length;
    });
  }

  void openMessages(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MessagesPage()),
    );
    fetchUnread();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.support_agent, size: 40),
          onPressed: () => openMessages(context),
        ),
        if (unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}