class User {
  final String id;
  final String email;
  final String name;
  final String? officeAddress;
  final double? officeLat;
  final double? officeLng;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.officeAddress,
    this.officeLat,
    this.officeLng,
    this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      officeAddress: json['officeAddress'],
      officeLat: json['officeLat'],
      officeLng: json['officeLng'],
      preferences: json['preferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'officeAddress': officeAddress,
      'officeLat': officeLat,
      'officeLng': officeLng,
      'preferences': preferences,
    };
  }
}