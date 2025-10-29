import 'package:flutter/foundation.dart';
import '../models/food_option.dart';
import 'dart:math';

class FoodService extends ChangeNotifier {
  List<FoodOption> _currentLocationOptions = [];
  List<FoodOption> _destinationOptions = [];
  bool _isLoading = false;

  List<FoodOption> get currentLocationOptions => _currentLocationOptions;
  List<FoodOption> get destinationOptions => _destinationOptions;
  bool get isLoading => _isLoading;

  final List<Restaurant> _restaurants = [
    Restaurant(
      id: '1',
      name: 'Spice Garden',
      cuisine: 'Indian',
      rating: 4.5,
      imageUrl: '',
      distance: 1.2,
    ),
    Restaurant(
      id: '2',
      name: 'Pizza Palace',
      cuisine: 'Italian',
      rating: 4.3,
      imageUrl: '',
      distance: 2.0,
    ),
    Restaurant(
      id: '3',
      name: 'Burger House',
      cuisine: 'American',
      rating: 4.2,
      imageUrl: '',
      distance: 1.5,
    ),
    Restaurant(
      id: '4',
      name: 'Chinese Wok',
      cuisine: 'Chinese',
      rating: 4.4,
      imageUrl: '',
      distance: 1.8,
    ),
    Restaurant(
      id: '5',
      name: 'Sushi Bar',
      cuisine: 'Japanese',
      rating: 4.6,
      imageUrl: '',
      distance: 2.5,
    ),
  ];

  final List<String> _dishes = [
    'Biryani',
    'Margherita Pizza',
    'Cheese Burger',
    'Fried Rice',
    'California Roll',
    'Butter Chicken',
    'Pasta Alfredo',
    'Chicken Wings',
    'Noodles',
    'Ramen',
  ];

  Future<void> fetchFoodOptions(String weather, int currentHour) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _currentLocationOptions = _generateFoodOptions('current', weather, currentHour);
    _destinationOptions = _generateFoodOptions('destination', weather, currentHour);

    _currentLocationOptions = _applyAIRecommendations(_currentLocationOptions, weather, currentHour);
    _destinationOptions = _applyAIRecommendations(_destinationOptions, weather, currentHour);

    _isLoading = false;
    notifyListeners();
  }

  List<FoodOption> _generateFoodOptions(String locationType, String weather, int currentHour) {
    final random = Random();
    List<FoodOption> options = [];

    for (var restaurant in _restaurants) {
      for (var provider in FoodProvider.values) {
        final dishIndex = random.nextInt(_dishes.length);
        final basePrice = 150.0 + random.nextInt(200);
        final deliveryTime = locationType == 'current'
            ? 20 + random.nextInt(20)
            : 30 + random.nextInt(30);
        final deliveryFee = locationType == 'current'
            ? 20.0 + random.nextInt(20)
            : 30.0 + random.nextInt(30);

        options.add(FoodOption(
          restaurant: restaurant,
          provider: provider,
          dishName: _dishes[dishIndex],
          price: basePrice.toDouble(),
          deliveryTimeMinutes: deliveryTime,
          deliveryFee: deliveryFee.toDouble(),
          locationType: locationType,
        ));
      }
    }

    return options;
  }

  List<FoodOption> _applyAIRecommendations(
    List<FoodOption> options,
    String weather,
    int currentHour,
  ) {
    final sortedByPrice = List<FoodOption>.from(options)
      ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    final sortedByTime = List<FoodOption>.from(options)
      ..sort((a, b) => a.deliveryTimeMinutes.compareTo(b.deliveryTimeMinutes));

    FoodOption? recommended;
    String? reason;

    if (currentHour >= 12 && currentHour < 14) {
      recommended = sortedByTime.first;
      reason = 'Quick delivery for lunch time';
    } else if (currentHour >= 19 && currentHour < 21) {
      recommended = sortedByTime.first;
      reason = 'Fast delivery for dinner';
    } else if (weather.toLowerCase().contains('rain')) {
      recommended = options.firstWhere(
        (o) => o.restaurant.distance < 2.0,
        orElse: () => sortedByTime.first,
      );
      reason = 'Nearby restaurant due to rain';
    } else {
      recommended = sortedByPrice.first;
      reason = 'Best value for money';
    }

    return options.map((option) {
      if (option == recommended) {
        return FoodOption(
          restaurant: option.restaurant,
          provider: option.provider,
          dishName: option.dishName,
          price: option.price,
          deliveryTimeMinutes: option.deliveryTimeMinutes,
          deliveryFee: option.deliveryFee,
          isRecommended: true,
          reason: reason,
          locationType: option.locationType,
        );
      }
      return option;
    }).toList();
  }

  String getDeepLink(FoodOption option) {
    switch (option.provider) {
      case FoodProvider.swiggy:
        return 'https://www.swiggy.com/';
      case FoodProvider.zomato:
        return 'https://www.zomato.com/';
      default:
        return '';
    }
  }
}
