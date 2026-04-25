class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String language;
  final String currency;
  final bool hasPassword;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.language = 'en',
    this.currency = 'IDR',
    this.hasPassword = true,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] ?? j['_id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        avatar: j['avatar'],
        language: j['language'] ?? 'en',
        currency: j['currency'] ?? 'IDR',
        hasPassword: j['hasPassword'] ?? true,
        phone: j['phone'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'language': language,
    'currency': currency,
    'hasPassword': hasPassword,
    'phone': phone,
  };
}
