import 'package:flutter/material.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // For testing purposes - simulate login
  void loginTestUser() {
    _currentUser = User(
      id: 'test_user_123',
      email: 'test@example.com',
      name: 'Test User',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  // Logout
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Set current user (for when you implement real authentication)
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
