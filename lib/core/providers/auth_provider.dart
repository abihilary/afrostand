import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return response.user != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password, String? fullName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null && fullName.isNotEmpty ? {'full_name': fullName} : null,
      );
      _isLoading = false;
      notifyListeners();
      return response.user != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
