enum FoodProvider { swiggy, zomato }

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final String imageUrl;
  final double distance;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.imageUrl,
    required this.distance,
  });
}

class FoodOption {
  final Restaurant restaurant;
  final FoodProvider provider;
  final String dishName;
  final double price;
  final int deliveryTimeMinutes;
  final double deliveryFee;
  final bool isRecommended;
  final String? reason;
  final String locationType; // 'current' or 'destination'

  FoodOption({
    required this.restaurant,
    required this.provider,
    required this.dishName,
    required this.price,
    required this.deliveryTimeMinutes,
    required this.deliveryFee,
    this.isRecommended = false,
    this.reason,
    required this.locationType,
  });

  double get totalPrice => price + deliveryFee;

  String get providerName {
    return provider == FoodProvider.swiggy ? 'Swiggy' : 'Zomato';
  }
}