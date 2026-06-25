import 'chapter_model.dart';

class SubjectModel {
  final String id;
  final String name;
  final String emoji;
  final List<ChapterModel> chapters;
  final double completionPercent; // Range 0.0 to 100.0

  SubjectModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.chapters,
    required this.completionPercent,
  });

  SubjectModel copyWith({
    String? id,
    String? name,
    String? emoji,
    List<ChapterModel>? chapters,
    double? completionPercent,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      chapters: chapters ?? this.chapters,
      completionPercent: completionPercent ?? this.completionPercent,
    );
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '',
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((c) => ChapterModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      completionPercent: (json['completionPercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'completionPercent': completionPercent,
    };
  }
}
