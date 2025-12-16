class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String role;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'is_active': true,
    };
  }
}
