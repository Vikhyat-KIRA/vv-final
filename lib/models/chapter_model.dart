class ChapterModel {
  final String id;
  final String title;
  final int weightage;
  final int status; // 0=not started, 1=in progress, 2=completed

  ChapterModel({
    required this.id,
    required this.title,
    required this.weightage,
    required this.status,
  });

  ChapterModel copyWith({
    String? id,
    String? title,
    int? weightage,
    int? status,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      title: title ?? this.title,
      weightage: weightage ?? this.weightage,
      status: status ?? this.status,
    );
  }

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      weightage: json['weightage'] ?? 0,
      status: json['status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'weightage': weightage,
      'status': status,
    };
  }
}
