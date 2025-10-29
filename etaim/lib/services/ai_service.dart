import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../models/dashboard.dart';
import '../models/commute_option.dart';
import 'dart:math';

class AIInsight {
  final String title;
  final String description;
  final String icon;
  final String priority; // 'high', 'medium', 'low'

  AIInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
  });
}

class AIService extends ChangeNotifier {
  List<Dashboard> _dashboards = [];
  List<AIInsight> _insights = [];
  bool _isLoading = false;

  List<Dashboard> get dashboards => _dashboards;
  List<AIInsight> get insights => _insights;
  bool get isLoading => _isLoading;

  Future<void> createDashboard(
    String name,
    LocationModel from,
    LocationModel to,
    DateTime officeLoginTime,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final dashboard = Dashboard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      from: from,
      to: to,
      officeLoginTime: officeLoginTime,
      createdAt: DateTime.now(),
    );

    _dashboards.add(dashboard);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> generateInsights(
    Dashboard dashboard,
    String weather,
    int commuteTimeMinutes,
    List<CommuteOption> commuteOptions,
  ) async {
    _isLoading = true;
    _insights = [];
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();
    final officeTime = dashboard.officeLoginTime;
    final minutesToOffice = officeTime.difference(now).inMinutes;

    // Timing Insight
    if (minutesToOffice > commuteTimeMinutes + 30) {
      final bufferTime = minutesToOffice - commuteTimeMinutes;
      final orderTime = now.add(Duration(minutes: 10));
      final eatTime = bufferTime - 20; // 20 mins to eat

      if (eatTime > 0) {
        _insights.add(AIInsight(
          title: '🍽️ Food Timing Recommendation',
          description: 'You have $bufferTime minutes buffer. Order food at ${_formatTime(orderTime)} to eat at current location. You\'ll have $eatTime minutes to enjoy your meal.',
          icon: '🍽️',
          priority: 'high',
        ));
      } else {
        _insights.add(AIInsight(
          title: '🥡 Destination Delivery',
          description: 'Order food now for delivery to your destination. It will arrive around ${_formatTime(officeTime.subtract(const Duration(minutes: 5)))}.',
          icon: '🥡',
          priority: 'medium',
        ));
      }
    } else if (minutesToOffice > commuteTimeMinutes) {
      _insights.add(AIInsight(
        title: '⏰ Leave Soon',
        description: 'You should start your commute in ${minutesToOffice - commuteTimeMinutes} minutes to reach on time.',
        icon: '⏰',
        priority: 'high',
      ));
    } else {
      _insights.add(AIInsight(
        title: '🚨 Running Late',
        description: 'You\'re running ${commuteTimeMinutes - minutesToOffice} minutes late! Book fastest commute option now.',
        icon: '🚨',
        priority: 'high',
      ));
    }

    // Commute Insight
    final recommendedCommute = commuteOptions.firstWhere(
      (o) => o.isRecommended,
      orElse: () => commuteOptions.first,
    );

    _insights.add(AIInsight(
      title: '🚗 Best Commute Option',
      description: '${recommendedCommute.providerName} ${recommendedCommute.typeName} - ₹${recommendedCommute.price.toStringAsFixed(0)} • ${recommendedCommute.etaMinutes} mins • ${recommendedCommute.reason ?? "Recommended"}',
      icon: '🚗',
      priority: 'high',
    ));

    // Weather-based insight
    if (weather.toLowerCase().contains('rain')) {
      _insights.add(AIInsight(
        title: '🌧️ Weather Alert',
        description: 'It\'s raining! Consider cab option and add 10-15 minutes buffer time for traffic.',
        icon: '🌧️',
        priority: 'medium',
      ));
    } else if (weather.toLowerCase().contains('sunny')) {
      _insights.add(AIInsight(
        title: '☀️ Pleasant Weather',
        description: 'Great weather for bike commute! Save money and enjoy the ride.',
        icon: '☀️',
        priority: 'low',
      ));
    }

    // Time-based insight
    final hour = now.hour;
    if (hour >= 8 && hour <= 10) {
      _insights.add(AIInsight(
        title: '🚦 Peak Traffic Alert',
        description: 'Heavy traffic expected. Your commute might take 20% longer than usual.',
        icon: '🚦',
        priority: 'medium',
      ));
    }

    _isLoading = false;
    notifyListeners();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void deleteDashboard(String id) {
    _dashboards.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}