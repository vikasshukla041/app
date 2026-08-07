import 'package:equatable/equatable.dart';

/// Core User domain entity used across the application.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.fullname,
  });

  /// Network responses are untrusted input, so this narrows the payload and
  /// returns null rather than fabricating a User from missing fields.
  ///
  /// [id] and [username] identify the account and must be present. [fullName]
  /// is display-only, so it falls back to the username.
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
