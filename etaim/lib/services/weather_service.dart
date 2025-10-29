import 'package:flutter/foundation.dart';
import 'dart:math';

class WeatherService extends ChangeNotifier {
  String _currentWeather = 'Clear';
  double _temperature = 25.0;
  bool _isLoading = false;

  String get currentWeather => _currentWeather;
  double get temperature => _temperature;
  bool get isLoading => _isLoading;

  final List<String> _weatherConditions = [
    'Clear',
    'Sunny',
    'Partly Cloudy',
    'Cloudy',
    'Rainy',
    'Light Rain',
  ];

  Future<void> fetchWeather() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final random = Random();
    final hour = DateTime.now().hour;

    // Simulate weather based on time
    if (hour >= 6 && hour < 12) {
      _currentWeather = _weatherConditions[random.nextInt(2)]; // Clear or Sunny
      _temperature = 22 + random.nextInt(8).toDouble();
    } else if (hour >= 12 && hour < 18) {
      _currentWeather = _weatherConditions[random.nextInt(4)];
      _temperature = 28 + random.nextInt(7).toDouble();
    } else {
      _currentWeather = _weatherConditions[random.nextInt(_weatherConditions.length)];
      _temperature = 18 + random.nextInt(10).toDouble();
    }

    _isLoading = false;
    notifyListeners();
  }

  String getWeatherIcon() {
    if (_currentWeather.toLowerCase().contains('rain')) {
      return '🌧️';
    } else if (_currentWeather.toLowerCase().contains('cloud')) {
      return '☁️';
    } else if (_currentWeather.toLowerCase().contains('sunny') || 
               _currentWeather.toLowerCase().contains('clear')) {
      return '☀️';
    }
    return '🌤️';
  }
}