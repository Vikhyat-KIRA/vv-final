import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { syncing, synced, error }

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.synced);

  void setSyncing() {
    state = SyncStatus.syncing;
  }

  void setSynced() {
    state = SyncStatus.synced;
  }

  void setError() {
    state = SyncStatus.error;
  }
}

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});
