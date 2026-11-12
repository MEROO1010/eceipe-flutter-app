class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName = '',
    this.lastName = '',
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        username: (json['username'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        firstName: (json['first_name'] ?? '') as String,
        lastName: (json['last_name'] ?? '') as String,
      );

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? username : name;
  }

  String get initials =>
      (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase();
}
