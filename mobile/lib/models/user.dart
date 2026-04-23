class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;

  User({required this.id, required this.name, required this.email, this.avatar});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] ?? j['_id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        avatar: j['avatar'],
      );
}
