import 'package:flutter/foundation.dart';
import '../models/commute_option.dart';
import '../models/location.dart';
import 'dart:math';

class CommuteService extends ChangeNotifier {
  List<CommuteOption> _options = [];
  bool _isLoading = false;

  List<CommuteOption> get options => _options;
  bool get isLoading => _isLoading;

  Future<void> fetchCommuteOptions(
    LocationModel from,
    LocationModel to,
    String weather,
    int currentHour,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    final distance = _calculateDistance(from, to);
    final baseTime = (distance / 30 * 60).round(); // Base time in minutes

    List<CommuteOption> allOptions = [];

    // Generate options for each provider and type
    for (var provider in [CommuteProvider.rapido, CommuteProvider.ola, CommuteProvider.uber]) {
      for (var type in CommuteType.values) {
        allOptions.add(_generateOption(
          provider,
          type,
          distance,
          baseTime,
          weather,
          currentHour,
        ));
      }
    }

    // Add own vehicle option
    allOptions.add(CommuteOption(
      provider: CommuteProvider.ownVehicle,
      type: CommuteType.bike,
      price: 0,
      etaMinutes: baseTime,
      arrivalMinutes: 0,
      distance: distance,
      isRecommended: false,
      reason: 'No cost',
    ));

    // Apply AI recommendations based on weather and time
    allOptions = _applyAIRecommendations(allOptions, weather, currentHour);

    _options = allOptions;
    _isLoading = false;
    notifyListeners();
  }

  CommuteOption _generateOption(
    CommuteProvider provider,
    CommuteType type,
    double distance,
    int baseTime,
    String weather,
    int currentHour,
  ) {
    final random = Random();

    // Price calculation
    double basePrice = 0;
    switch (type) {
      case CommuteType.bike:
        basePrice = distance * 8 + random.nextInt(20);
        break;
      case CommuteType.auto:
        basePrice = distance * 12 + random.nextInt(30);
        break;
      case CommuteType.cab:
        basePrice = distance * 15 + random.nextInt(50);
        break;
    }

    // Provider-specific pricing
    double multiplier = 1.0;
    switch (provider) {
      case CommuteProvider.rapido:
        multiplier = 0.9;
        break;
      case CommuteProvider.ola:
        multiplier = 1.0;
        break;
      case CommuteProvider.uber:
        multiplier = 1.1;
        break;
      case CommuteProvider.ownVehicle:
        multiplier = 0;
        break;
    }

    final price = basePrice * multiplier;
    final arrivalTime = 3 + random.nextInt(7); // 3-10 minutes
    final eta = baseTime + random.nextInt(10) - 5;

    return CommuteOption(
      provider: provider,
      type: type,
      price: price,
      etaMinutes: eta,
      arrivalMinutes: arrivalTime,
      distance: distance,
    );
  }

  List<CommuteOption> _applyAIRecommendations(
    List<CommuteOption> options,
    String weather,
    int currentHour,
  ) {
    // Find cheapest and fastest
    final sortedByPrice = List<CommuteOption>.from(options)
      ..sort((a, b) => a.price.compareTo(b.price));
    final sortedByTime = List<CommuteOption>.from(options)
      ..sort((a, b) => (a.etaMinutes + a.arrivalMinutes).compareTo(b.etaMinutes + b.arrivalMinutes));

    CommuteOption? recommended;
    String? reason;

    // Weather-based recommendations
    if (weather.toLowerCase().contains('rain')) {
      // Recommend cab during rain
      recommended = options.firstWhere(
        (o) => o.type == CommuteType.cab,
        orElse: () => sortedByPrice.first,
      );
      reason = 'Recommended due to rainy weather';
    } else if (currentHour >= 22 || currentHour <= 5) {
      // Late night - recommend cab
      recommended = options.firstWhere(
        (o) => o.type == CommuteType.cab,
        orElse: () => sortedByPrice.first,
      );
      reason = 'Recommended for safety during late hours';
    } else if (weather.toLowerCase().contains('sunny') || weather.toLowerCase().contains('clear')) {
      // Good weather - recommend bike for cost savings
      recommended = options.firstWhere(
        (o) => o.type == CommuteType.bike && o.provider != CommuteProvider.ownVehicle,
        orElse: () => sortedByPrice.first,
      );
      reason = 'Best option - Good weather & economical';
    } else {
      // Default - recommend cheapest
      recommended = sortedByPrice.first;
      reason = 'Most economical option';
    }

    return options.map((option) {
      if (option == recommended) {
        return CommuteOption(
          provider: option.provider,
          type: option.type,
          price: option.price,
          etaMinutes: option.etaMinutes,
          arrivalMinutes: option.arrivalMinutes,
          distance: option.distance,
          isRecommended: true,
          reason: reason,
        );
      }
      return option;
    }).toList();
  }

  double _calculateDistance(LocationModel from, LocationModel to) {
    // Haversine formula
    const R = 6371; // Earth's radius in km

    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLat = (to.latitude - from.latitude) * pi / 180;
    final dLon = (to.longitude - from.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  String getDeepLink(CommuteOption option) {
    switch (option.provider) {
      case CommuteProvider.rapido:
        return 'https://rapido.bike/';
      case CommuteProvider.ola:
        return 'https://www.olacabs.com/';
      case CommuteProvider.uber:
        return 'https://www.uber.com/';
      default:
        return '';
    }
  }
}