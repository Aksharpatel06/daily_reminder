import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_services.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.authServices;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Sign up method
  Future<bool> signUp({
    required String email,
    required String username,
    required String area,
    bool isAdmin = false, // Defaults to false
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signUpWithEmail(
        email: email,
        username: username,
        area: area,
        isAdmin: isAdmin, // Pass the isAdmin parameter
      );

      if (user != null) {
        // AppPref.appPref.saveUser(user);
        _currentUser = user;
        _setLoading(false);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Sign in method
  Future<bool> signIn({required String area, required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signInWithEmail(area: area, email: email);

      if (user != null) {
        // AppPref.appPref.saveUser(user);
        _currentUser = user;
        _setLoading(false);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Load current user from Firebase
  Future<void> loadCurrentUser() async {
    final currentAuthUser = _authService.currentUser;
    if (currentAuthUser != null) {
      final user = await _authService.getUserById(currentAuthUser.uid);
      _currentUser = user;
      notifyListeners();
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
