import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Mock user database
  final Map<String, Map<String, dynamic>> _users = {
    'admin@etaim.com': {
      'password': 'admin123',
      'name': 'Admin',
      'id': '1',
    },
    'user@etaim.com': {
      'password': 'user123',
      'name': 'User',
      'id': '2',
    },
    'demo@etaim.com': {
      'password': 'demo123',
      'name': 'Demo',
      'id': '3',
    },
    'uday@etaim.com': {
      'password': 'admin123',
      'name': 'Uday',
      'id': '4',
    },
  };

  AuthService() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && _users.containsKey(email)) {
      _currentUser = User(
        id: _users[email]!['id'],
        email: email,
        name: _users[email]!['name'],
      );
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    if (_users.containsKey(email) && _users[email]!['password'] == password) {
      _currentUser = User(
        id: _users[email]!['id'],
        email: email,
        name: _users[email]!['name'],
      );
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signup(String email, String password, String name) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(email)) {
      return false; // User already exists
    }

    _users[email] = {
      'password': password,
      'name': name,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    return await login(email, password);
  }

  Future<bool> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return _users.containsKey(email);
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');

    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    _currentUser = User(
      id: 'guest',
      email: 'guest@etaim.com',
      name: 'Guest',
    );
    _isAuthenticated = true;
    notifyListeners();
  }
}