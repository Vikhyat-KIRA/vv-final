import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_file_model.dart';
import 'either.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: '773443742576-rab15ntpgmeeffg9isalt55pamcqstc3.apps.googleusercontent.com',
      clientSecret: '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',
      redirectPort: 3000,
      scopes: [drive.DriveApi.driveFileScope],
    ),
  );

  Future<Either<Failure, T>> runSafe<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firebase error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    final credentials = await _googleSignIn.signIn();
    if (credentials == null || credentials.accessToken == null) return null;

    final client = GoogleAuthClient({'Authorization': 'Bearer ${credentials.accessToken}'});
    return drive.DriveApi(client);
  }

  Future<String> _getOrCreateVaultFolderId(drive.DriveApi driveApi) async {
    const folderName = "VidyaVerse Vault";
    
    final query = "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";
    final fileList = await driveApi.files.list(q: query, spaces: 'drive');
    
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id!;
    }
    
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';
      
    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }

  /// Uploads a file to Google Drive under "VidyaVerse Vault" or locally based on preference
  /// Reports upload progress via onProgress callback (simulated for Drive)
  Future<VaultFileModel> uploadFile(
    File file,
    String subject,
    String fileType,
    String uid, {
    Function(double)? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storagePref = prefs.getString('storage_preference') ?? 'drive';

    final filename = file.path.split(Platform.pathSeparator).last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final actualFileName = '${timestamp}_$filename';
    final sizeBytes = await file.length();

    String downloadUrl;
    String storageRef;

    if (storagePref == 'local') {
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/VidyaVerseVault');
      if (!await vaultDir.exists()) await vaultDir.create();

      final localFile = File('${vaultDir.path}/$actualFileName');
      await file.copy(localFile.path);

      downloadUrl = 'file://${localFile.path}';
      storageRef = localFile.path;

      if (onProgress != null) onProgress(1.0);
    } else {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        throw Exception("Could not authenticate with Google Drive.");
      }

      if (onProgress != null) onProgress(0.1);

      final folderId = await _getOrCreateVaultFolderId(driveApi);

      final driveFile = drive.File()
        ..name = actualFileName
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), sizeBytes);

      if (onProgress != null) onProgress(0.3);

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, webViewLink, webContentLink',
      );

      if (onProgress != null) onProgress(1.0);

      downloadUrl = result.webContentLink ?? result.webViewLink ?? '';
      storageRef = result.id!;
    }

    // Create Firestore entry
    final docRef = _firestore
        .collection('vault_meta')
        .doc(uid)
        .collection('files')
        .doc();

    final vaultFile = VaultFileModel(
      id: docRef.id,
      name: filename,
      subject: subject,
      fileType: fileType,
      downloadUrl: downloadUrl,
      storageRef: storageRef,
      sizeBytes: sizeBytes,
      uploadedAt: DateTime.now(),
    );

    await docRef.set(vaultFile.toMap());
    return vaultFile;
  }

  /// Real-time stream of all uploaded vault files for a specific user
  Stream<List<VaultFileModel>> getFiles(String uid) {
    return _firestore
        .collection('vault_meta')
        .doc(uid)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VaultFileModel.fromFirestore(doc))
            .toList());
  }

  /// Deletes the file from Google Drive and Firestore
  Future<void> deleteFile(VaultFileModel file, String uid) async {
    if (file.downloadUrl.startsWith('file://')) {
      final localFile = File(file.storageRef);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    } else {
      // 1. Delete from Google Drive
      try {
        final driveApi = await _getDriveApi();
        if (driveApi != null) {
          await driveApi.files.delete(file.storageRef);
        }
      } catch (e) {
        debugPrint('Error deleting file from Drive: $e');
        // Continue deleting metadata even if Drive file is already gone
      }
    }

    // 2. Delete Firestore Metadata Document
    await _firestore
        .collection('vault_meta')
        .doc(uid)
        .collection('files')
        .doc(file.id)
        .delete();
  }

  /// Uploads a file to Google Drive under "VidyaVerse Vault"
  /// Reports upload progress via onProgress callback (simulated for Drive)
  Future<VaultFileModel> uploadGuildFile(
    File file,
    String guildId,
    String fileType,
    String uploadedByUid, {
    Function(double)? onProgress,
  }) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception("Could not authenticate with Google Drive.");
    }

    if (onProgress != null) onProgress(0.1);

    final folderId = await _getOrCreateVaultFolderId(driveApi);
    final filename = file.path.split(Platform.pathSeparator).last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final actualFileName = '${timestamp}_$filename';

    final driveFile = drive.File()
      ..name = actualFileName
      ..parents = [folderId];

    final media = drive.Media(file.openRead(), await file.length());

    if (onProgress != null) onProgress(0.3);

    final result = await driveApi.files.create(
      driveFile,
      uploadMedia: media,
      $fields: 'id, webViewLink, webContentLink',
    );

    if (onProgress != null) onProgress(1.0);

    final downloadUrl = result.webContentLink ?? result.webViewLink ?? '';
    final storageRef = result.id!;
    final sizeBytes = await file.length();

    // Create Firestore entry under guilds/$guildId/files/$fileId
    final docRef = _firestore
        .collection('guilds')
        .doc(guildId)
        .collection('files')
        .doc();

    final vaultFile = VaultFileModel(
      id: docRef.id,
      name: filename,
      subject: 'Guild',
      fileType: fileType,
      downloadUrl: downloadUrl,
      storageRef: storageRef,
      sizeBytes: sizeBytes,
      uploadedAt: DateTime.now(),
    );

    await docRef.set(vaultFile.toMap());
    return vaultFile;
  }

  /// Real-time stream of all uploaded guild files for a specific guild
  Stream<List<VaultFileModel>> getGuildFiles(String guildId) {
    return _firestore
        .collection('guilds')
        .doc(guildId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VaultFileModel.fromFirestore(doc))
            .toList());
  }

  /// Deletes the guild file from Google Drive and Firestore
  Future<void> deleteGuildFile(VaultFileModel file, String guildId) async {
    // 1. Delete from Google Drive
    try {
      final driveApi = await _getDriveApi();
      if (driveApi != null) {
        await driveApi.files.delete(file.storageRef);
      }
    } catch (e) {
      debugPrint('Error deleting guild file from Drive: $e');
    }

    // 2. Delete Firestore Metadata Document
    await _firestore
        .collection('guilds')
        .doc(guildId)
        .collection('files')
        .doc(file.id)
        .delete();
  }
}
