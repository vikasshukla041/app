import 'package:equatable/equatable.dart';

/// The authenticated user, as returned by `POST /api/auth/login`.
///
/// Immutable and value-comparable so it can live inside a Cubit state
/// without triggering rebuilds when nothing actually changed.
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.fullName,
  });

  /// Returns null instead of throwing when the payload is missing or
  /// malformed — network responses are untrusted input.
  static User? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'username': final String username,
      'fullName': final String fullName,
    }) {
      return User(id: id, username: username, fullName: fullName);
    }
    return null;
  }

  final String id;
  final String username;
  final String fullName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'username': username,
    'fullName': fullName,
  };

  @override
  List<Object?> get props => <Object?>[id, username, fullName];
}
