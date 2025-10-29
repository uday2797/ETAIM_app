class LocationModel {
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;

  LocationModel({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      placeId: json['placeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
    };
  }
}