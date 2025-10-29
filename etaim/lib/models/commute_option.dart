enum CommuteType { bike, auto, cab }
enum CommuteProvider { rapido, ola, uber, ownVehicle }

class CommuteOption {
  final CommuteProvider provider;
  final CommuteType type;
  final double price;
  final int etaMinutes;
  final int arrivalMinutes;
  final double distance;
  final bool isRecommended;
  final String? reason;

  CommuteOption({
    required this.provider,
    required this.type,
    required this.price,
    required this.etaMinutes,
    required this.arrivalMinutes,
    required this.distance,
    this.isRecommended = false,
    this.reason,
  });

  String get providerName {
    switch (provider) {
      case CommuteProvider.rapido:
        return 'Rapido';
      case CommuteProvider.ola:
        return 'Ola';
      case CommuteProvider.uber:
        return 'Uber';
      case CommuteProvider.ownVehicle:
        return 'Own Vehicle';
    }
  }

  String get typeName {
    switch (type) {
      case CommuteType.bike:
        return 'Bike';
      case CommuteType.auto:
        return 'Auto';
      case CommuteType.cab:
        return 'Cab';
    }
  }

  factory CommuteOption.fromJson(Map<String, dynamic> json) {
    return CommuteOption(
      provider: CommuteProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      ),
      type: CommuteType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      price: json['price'].toDouble(),
      etaMinutes: json['etaMinutes'],
      arrivalMinutes: json['arrivalMinutes'],
      distance: json['distance'].toDouble(),
      isRecommended: json['isRecommended'] ?? false,
      reason: json['reason'],
    );
  }
}