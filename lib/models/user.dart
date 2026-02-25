class AppUser {
  final String id;
  String name, email, avatar, currency;
  double budget;
  AppUser({required this.id, required this.name, required this.email,
      this.avatar = '', this.budget = 5000, this.currency = '₹'}) {
    if (avatar.isEmpty) genAvatar();
  }
  void genAvatar() {
    final p = name.trim().split(' ');
    avatar = p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }
  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'email': email,
        'avatar': avatar, 'budget': budget, 'currency': currency
      };
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
      id: j['id'],
      name: j['name'],
      email: j['email'],
      avatar: j['avatar'] ?? '',
      budget: (j['budget'] as num?)?.toDouble() ?? 5000,
      currency: j['currency'] ?? '₹');
}
