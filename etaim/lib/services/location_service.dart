import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location.dart';

class LocationService extends ChangeNotifier {
  LocationModel? _currentLocation;
  List<LocationModel> _searchSuggestions = [];
  bool _isLoading = false;

  LocationModel? get currentLocation => _currentLocation;
  List<LocationModel> get searchSuggestions => _searchSuggestions;
  bool get isLoading => _isLoading;

  // Mock locations for suggestions
  final List<Map<String, dynamic>> _mockLocations = [
    {
      'address': 'Cyber Towers, Hitech City, Hyderabad',
      'latitude': 17.4485,
      'longitude': 78.3908,
    },
    {
      'address': 'Rajiv Gandhi International Airport, Shamshabad, Hyderabad',
      'latitude': 17.2403,
      'longitude': 78.4294,
    },
    {
      'address': 'Charminar, Hyderabad',
      'latitude': 17.3616,
      'longitude': 78.4747,
    },
    {
      'address': 'Gachibowli, Hyderabad',
      'latitude': 17.4399,
      'longitude': 78.3489,
    },
    {
      'address': 'Banjara Hills, Hyderabad',
      'latitude': 17.4239,
      'longitude': 78.4738,
    },
    {
      'address': 'Secunderabad Railway Station, Hyderabad',
      'latitude': 17.4340,
      'longitude': 78.5011,
    },
    {
      'address': 'KPHB Colony, Hyderabad',
      'latitude': 17.4904,
      'longitude': 78.3953,
    },
    {
      'address': 'Begumpet, Hyderabad',
      'latitude': 17.4435,
      'longitude': 78.4672,
    },
    {
      'address': 'Kukatpally, Hyderabad',
      'latitude': 17.4849,
      'longitude': 78.4138,
    },
    {
      'address': 'Madhapur, Hyderabad',
      'latitude': 17.4483,
      'longitude': 78.3915,
    },
  ];

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Use mock location
        _currentLocation = LocationModel(
          address: 'KPHB Colony, Hyderabad',
          latitude: 17.4904,
          longitude: 78.3953,
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentLocation = LocationModel(
            address: 'KPHB Colony, Hyderabad',
            latitude: 17.4904,
            longitude: 78.3953,
          );
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentLocation = LocationModel(
          address: '${place.street}, ${place.locality}, ${place.administrativeArea}',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      // Fallback to mock location
      _currentLocation = LocationModel(
        address: 'KPHB Colony, Hyderabad',
        latitude: 17.4904,
        longitude: 78.3953,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchLocations(String query) async {
    if (query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    // Filter mock locations based on query
    _searchSuggestions = _mockLocations
        .where((loc) => loc['address'].toLowerCase().contains(query.toLowerCase()))
        .map((loc) => LocationModel(
              address: loc['address'],
              latitude: loc['latitude'],
              longitude: loc['longitude'],
            ))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  void clearSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }

  double calculateDistance(LocationModel from, LocationModel to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000; // Convert to kilometers
  }
}