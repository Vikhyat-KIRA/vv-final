import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_queue_service.dart';
import '../services/dm_service.dart';

/// Streams connectivity changes
final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Derived bool: true when fully offline
final isOfflineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityProvider);
  return async.maybeWhen(
    data: (results) =>
        results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none),
    orElse: () => false,
  );
});

/// Watches connectivity and auto-flushes the offline queue when back online
final offlineQueueFlusherProvider = Provider<void>((ref) {
  ref.listen<bool>(isOfflineProvider, (wasOffline, isOffline) {
    // Transition from offline -> online: flush queued messages
    if (wasOffline == true && !isOffline) {
      OfflineQueueService().flush((type, payload) async {
        // Only text messages are queued currently
        if (type == 'text') {
          final dmId = payload['dmId'] as String;
          final senderId = payload['senderId'] as String;
          final text = payload['text'] as String;
          await DmService().sendMessage(dmId, senderId, text);
        }
      });
    }
  });
});
