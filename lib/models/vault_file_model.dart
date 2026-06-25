import 'package:cloud_firestore/cloud_firestore.dart';

class VaultFileModel {
  final String id;
  final String name;
  final String subject;
  final String fileType;
  final String downloadUrl;
  final String storageRef;
  final int sizeBytes;
  final DateTime uploadedAt;

  VaultFileModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.fileType,
    required this.downloadUrl,
    required this.storageRef,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  factory VaultFileModel.fromMap(String id, Map<String, dynamic> map) {
    return VaultFileModel(
      id: id,
      name: map['name'] ?? '',
      subject: map['subject'] ?? '',
      fileType: map['fileType'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      storageRef: map['storageRef'] ?? '',
      sizeBytes: map['sizeBytes'] ?? 0,
      uploadedAt: map['uploadedAt'] != null
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory VaultFileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return VaultFileModel.fromMap(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'fileType': fileType,
      'downloadUrl': downloadUrl,
      'storageRef': storageRef,
      'sizeBytes': sizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
