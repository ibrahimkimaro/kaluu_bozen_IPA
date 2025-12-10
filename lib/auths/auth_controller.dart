import 'package:flutter/material.dart';
import 'api_service.dart';

/// Authentication Controller using Provider/GetX pattern
/// Manages authentication state throughout the app
class AuthController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;
  String? get errorMessage => _errorMessage;
  String? get userEmail => _userData?['email'];
  String? get userName => _userData?['full_name'];
  String? get profilePicture {
    final picture = _userData?['profile_picture'];
    if (picture == null || picture.isEmpty) return null;

    // If it's already a full URL, return it as is
    if (picture.startsWith('http://') || picture.startsWith('https://')) {
      return picture;
    }

    // Otherwise, prepend the base URL
    return '${ApiService.baseUrl}$picture';
  }

  String? get phoneNumber => _userData?['phone_number'];
  String? get city => _userData?['city'];
  String? get country => _userData?['country'];

  /// Initialize authentication state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.init();
    _isAuthenticated = _apiService.isAuthenticated;

    if (_isAuthenticated) {
      _userData = await _apiService.getUserData();

      // Validate token by fetching profile
      final response = await _apiService.getProfile();
      if (response.isSuccess) {
        _userData = response.data?['user'];
        await _apiService.saveUserData(_userData!);
      } else {
        // Token invalid, clear auth
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String country,
    required String city,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
        country: country,
        city: city,
      );

      if (response.isSuccess) {
        _isAuthenticated = true;
        _userData = response.data?['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.isSuccess) {
        _isAuthenticated = true;
        _userData = response.data?['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.logout();

    _isAuthenticated = false;
    _userData = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Get user profile
  Future<bool> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getProfile();

      if (response.isSuccess) {
        _userData = response.data?['user'];
        await _apiService.saveUserData(_userData!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error fetching profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
    String? city,
    String? country,
    String? postalCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        country: country,
        postalCode: postalCode,
      );

      if (response.isSuccess) {
        _userData = response.data?['user'];
        await _apiService.saveUserData(_userData!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? 'Update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Update error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.isSuccess) {
        _isLoading = false;
        notifyListeners();
        // Force re-login after password change
        await logout();
        return true;
      } else {
        _errorMessage = response.error ?? 'Password change failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Password change error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.requestPasswordReset(email: email);

      _isLoading = false;
      if (!response.isSuccess) {
        _errorMessage = response.error;
      }
      notifyListeners();

      return response.isSuccess;
    } catch (e) {
      _errorMessage = 'Password reset request error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirm password reset
  Future<bool> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.confirmPasswordReset(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      _isLoading = false;
      if (!response.isSuccess) {
        _errorMessage = response.error;
      }
      notifyListeners();

      return response.isSuccess;
    } catch (e) {
      _errorMessage = 'Password reset error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
