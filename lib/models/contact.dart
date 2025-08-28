class Contact {
  final String contactId; 
  final String username;
  final String? profilePicture;

  const Contact({required this.contactId, required this.username, this.profilePicture});

  Map<String, dynamic> toMap() => {
        'contact_id': contactId,
        'username': username,
        'profile_picture': profilePicture,
      };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        contactId: map['contact_id'] as String,
        username: (map['username'] as String?) ?? 'Unknown',
        profilePicture: map['profile_picture'] as String?,
      );
}
