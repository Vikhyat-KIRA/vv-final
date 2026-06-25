import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'vault_service.dart';

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  Timer? _syncTimer;

  void start() {
    if (_syncTimer != null) return;
    
    // Sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final storagePref = prefs.getString('storage_preference');
      if (storagePref == 'drive') {
        // Assume VaultService has a sync method, or we just call the relevant sync mechanism
        // For now, we will just simulate a sync if a true sync method isn't globally exposed
        // Ideally: await VaultService().syncLocalToDrive();
      }
    });
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
