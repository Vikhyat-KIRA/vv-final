import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'firebase_options.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/background_sync_service.dart';
import 'app.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Preserve native splash until we finish init
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Run Firebase init and local storage init in PARALLEL
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    LocalStorageService().initialize(),
  ]);

  // Configure Firestore offline persistence after Firebase is ready
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService.initialize();
  BackgroundSyncService().start();

  // Remove native splash — Flutter will take over now
  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: VidyaverseApp(),
    ),
  );

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    doWhenWindowReady(() {
      const initialSize = Size(1280, 720);
      appWindow.minSize = const Size(800, 600);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.show();
    });
  }
}
