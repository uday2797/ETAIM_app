import 'location.dart';

class Dashboard {
  final String id;
  final String name;
  final LocationModel from;
  final LocationModel to;
  final DateTime officeLoginTime;
  final bool isActive;
  final DateTime createdAt;

  Dashboard({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.officeLoginTime,
    this.isActive = true,
    required this.createdAt,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      id: json['id'],
      name: json['name'],
      from: LocationModel.fromJson(json['from']),
      to: LocationModel.fromJson(json['to']),
      officeLoginTime: DateTime.parse(json['officeLoginTime']),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'from': from.toJson(),
      'to': to.toJson(),
      'officeLoginTime': officeLoginTime.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}