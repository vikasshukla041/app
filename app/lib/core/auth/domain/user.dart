import 'package:equatable/equatable.dart';

/// Core User domain entity used across the application.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.fullname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullname: json['fullName'] as String? ?? '',
    );
  }

  final String id;
  final String username;
  final String fullname;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'username': username,
    'fullName': fullname,
  };

  @override
  List<Object?> get props => <Object?>[id, username, fullname];
}

