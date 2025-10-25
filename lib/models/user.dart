class User {
  final int id;
  final String fullName;
  final String username;
  final String email;

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    fullName: json['fullName'] ?? json['full_name'] ?? '',
    username: json['username'] ?? '',
    email: json['email'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'username': username,
    'email': email,
  };
}
