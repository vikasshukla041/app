import 'package:equatable/equatable.dart';

/// Core User domain entity used across the application.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.fullname,
  });

  /// network responses making narrows teh payload and return null rather thn a user misue missing field
  static User? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'username': final String username,
    } when id.isNotEmpty && username.isNotEmpty) {
      return User(
        id: id,
        username: username,
        fullname: switch (json) {
          {'fullName': final String name} when name.isNotEmpty => name,
          _ => username,
        },
      );
    }
    return null;
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
