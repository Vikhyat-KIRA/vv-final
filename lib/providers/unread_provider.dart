import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dm_service.dart';
import 'auth_provider.dart';

final unreadConversationsProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) {
    return Stream.value(0);
  }
  return DmService().getConversations(user.uid).map((conversations) {
    int totalUnread = 0;
    for (final conv in conversations) {
      totalUnread += conv.unreadCount;
    }
    return totalUnread;
  });
});
