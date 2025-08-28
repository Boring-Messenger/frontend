class UserProfile {
  final String userId;
  final String username;
  final String? profilePicturePath; // Implement eventually > < 

  const UserProfile({
    required this.userId,
    required this.username,
    this.profilePicturePath,
  });

  UserProfile copyWith({String? username, String? profilePicturePath}) {
    return UserProfile(
      userId: userId,
      username: username ?? this.username,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'profile_picture': profilePicturePath,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'] as String,
      username: map['username'] as String,
      profilePicturePath: map['profile_picture'] as String?,
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'username': username,
      // profile_picture intentionally omitted for v1; add later
    };
  }
}
