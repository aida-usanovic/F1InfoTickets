import '../core/json.dart';

class AuthResponse {
  final String token;
  final int userID;
  final String username;
  final String role;
  final DateTime expiresAt;

  AuthResponse({required this.token, required this.userID, required this.username, required this.role, required this.expiresAt});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'],
    userID: json['userID'],
    username: json['username'],
    role: json['role'],
    expiresAt: parseDateTime(json['expiresAt']),
  );
}

class User {
  final int userID;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String phone;
  final DateTime birthDate;
  final int roleID;
  final String? roleName;

  User({
    required this.userID,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.phone,
    required this.birthDate,
    required this.roleID,
    this.roleName,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) => User(
    userID: json['userID'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    username: json['username'],
    phone: json['phone'],
    birthDate: parseDate(json['birthDate']),
    roleID: json['roleID'],
    roleName: json['roleName'],
  );
}

class Role {
  final int roleID;
  final String name;
  final bool isSystemRole;

  Role({required this.roleID, required this.name, required this.isSystemRole});

  factory Role.fromJson(Map<String, dynamic> json) =>
      Role(roleID: json['roleID'], name: json['name'], isSystemRole: json['isSystemRole'] ?? false);
}
