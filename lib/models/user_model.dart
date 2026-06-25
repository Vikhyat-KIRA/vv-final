class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final int level;
  final int xp;
  final List<String> enrolledSubjects;
  final String username;
  final String grade;
  final String board;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.level,
    required this.xp,
    required this.enrolledSubjects,
    required this.username,
    this.grade = '',
    this.board = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      enrolledSubjects: List<String>.from(json['enrolledSubjects'] ?? []),
      username: json['username'] ?? '',
      grade: json['grade'] ?? '',
      board: json['board'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'level': level,
      'xp': xp,
      'enrolledSubjects': enrolledSubjects,
      'username': username,
      'grade': grade,
      'board': board,
    };
  }
}

extension UserLevelHelper on UserModel {
  String get rank {
    if (xp < 500) return 'Rookie';
    if (xp < 2000) return 'Scholar';
    if (xp < 5000) return 'Expert';
    return 'Master';
  }

  double get levelProgress {
    if (xp < 500) {
      return xp / 500.0;
    } else if (xp < 2000) {
      return (xp - 500) / 1500.0;
    } else if (xp < 5000) {
      return (xp - 2000) / 3000.0;
    } else {
      return 1.0;
    }
  }

  int get nextLevelXp {
    if (xp < 500) return 500;
    if (xp < 2000) return 2000;
    if (xp < 5000) return 5000;
    return xp; // Max level
  }

  int get currentTierBaseXp {
    if (xp < 500) return 0;
    if (xp < 2000) return 500;
    if (xp < 5000) return 2000;
    return 5000;
  }
}
