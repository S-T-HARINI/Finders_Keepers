import 'package:equatable/equatable.dart';

enum UserRole {
  student,
  faculty,
  staff,
  security,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.staff:
        return 'Campus Staff';
      case UserRole.security:
        return 'Campus Security';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.campusId,
    this.phoneNumber,
    this.role = UserRole.student,
    this.isAnonymous = false,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? campusId;
  final String? phoneNumber;
  final UserRole role;
  final bool isAnonymous;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? campusId,
    String? phoneNumber,
    UserRole? role,
    bool? isAnonymous,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      campusId: campusId ?? this.campusId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'campusId': campusId,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'isAnonymous': isAnonymous,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Campus User',
      campusId: data['campusId'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.student,
      ),
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      photoUrl: data['photoUrl'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static UserModel guest() {
    return UserModel(
      id: 'guest_user',
      email: 'guest@campus.edu',
      displayName: 'Guest Student',
      campusId: 'STU-DEMO',
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        campusId,
        phoneNumber,
        role,
        isAnonymous,
        photoUrl,
        createdAt,
      ];
}
