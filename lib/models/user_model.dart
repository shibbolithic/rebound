class AppUser1 {
  final String id;
  final String displayName;
  final String username;
  final String? profilePicture;
  final String role;

  AppUser1({
    required this.id,
    required this.displayName,
    required this.username,
    required this.role,
    this.profilePicture,
  });

  factory AppUser1.fromMap(Map<String, dynamic> map) {
    return AppUser1(
      id: map['id'],
      displayName: map['display_name'],
      username: map['username'],
      role: map['role'],
      profilePicture: map['profile_picture'],
    );
  }
}