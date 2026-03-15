import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatBadgeService {
  final SupabaseClient supabase = Supabase.instance.client;
  final String userId;
  int unreadCount = 0;

  StreamSubscription? _subscription;

  ChatBadgeService({required this.userId});

  /// Fetch unread messages for the current user
Future<void> fetchUnread() async {
  // Get conversation IDs first
  final member = await supabase
      .from('conversation_members')
      .select('conversation_id')
      .eq('user_id', userId);

  final ids = (member as List).map((e) => e['conversation_id']).toList();
  if (ids.isEmpty) {
    unreadCount = 0;
    return;
  }

  final unread = await supabase
      .from('messages')
      .select()
      .inFilter('conversation_id', ids)
      .eq('seen', false)
      .neq('sender_id', userId);

  unreadCount = (unread as List).length;
}

  /// Listen to real-time updates
  void listenUnread(void Function(int count) onUpdate) {
    _subscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((event) async {
      await fetchUnread();
      onUpdate(unreadCount); // notify listener
    });
  }

  void cancel() {
    _subscription?.cancel();
  }
}