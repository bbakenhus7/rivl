// providers/auth_provider.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _firebaseService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUser(firebaseUser.uid);
      } else {
        _user = null;
        _state = AuthState.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUser(String userId) async {
    try {
      _user = await _firebaseService.getUser(userId);
      if (_user != null) {
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // ============================================
  // SIGN IN
  // ============================================

  Future<bool> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter both email and password';
      notifyListeners();
      return false;
    }

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // SOCIAL SIGN IN
  // ============================================

  Future<bool> signInWithApple() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Create profile in Firestore if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final firebaseUser = userCredential.user!;
        final displayName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((n) => n != null && n.isNotEmpty).join(' ');

        await _firebaseService.createSocialUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName:
              displayName.isNotEmpty ? displayName : 'RIVL User',
        );
      }

      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      _state = AuthState.unauthenticated;
      if (e.code == AuthorizationErrorCode.canceled) {
        _errorMessage = null; // user cancelled, no error needed
      } else {
        _errorMessage = 'Apple Sign-In failed. Please try again.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Apple Sign-In failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential userCredential;
      final googleProvider = GoogleAuthProvider();

      if (kIsWeb) {
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        userCredential =
            await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      // Create profile in Firestore if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final firebaseUser = userCredential.user!;
        await _firebaseService.createSocialUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'RIVL User',
        );
      }

      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Google Sign-In failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // SIGN UP
  // ============================================

  Future<bool> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
    required String username,
    String? referralCode,
  }) async {
    // Validation
    if (email.isEmpty) {
      _errorMessage = 'Please enter your email';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Please enter a password';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _errorMessage = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    if (displayName.isEmpty) {
      _errorMessage = 'Please enter your name';
      notifyListeners();
      return false;
    }

    if (username.isEmpty) {
      _errorMessage = 'Please enter a username';
      notifyListeners();
      return false;
    }

    if (!_isValidUsername(username)) {
      _errorMessage = 'Username can only contain letters, numbers, and underscores';
      notifyListeners();
      return false;
    }

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create account first (username check requires auth)
      await _firebaseService.signUpWithEmail(
        email,
        password,
        displayName,
        username,
        referralCode: referralCode,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      _user = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to sign out. Please try again.';
      notifyListeners();
    }
  }

  // ============================================
  // PASSWORD RESET
  // ============================================

  Future<bool> resetPassword(String email) async {
    if (email.isEmpty) {
      _errorMessage = 'Please enter your email';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return false;
    }

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.resetPassword(email);
      _state = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Failed to send reset email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // UPDATE PROFILE
  // ============================================

  Future<bool> updateProfile({
    String? displayName,
    String? username,
    bool? notificationsEnabled,
  }) async {
    if (_user == null) return false;

    try {
      final updates = <String, dynamic>{};
      
      if (displayName != null) updates['displayName'] = displayName;
      if (username != null) {
        final isAvailable = await _firebaseService.isUsernameAvailable(username);
        if (!isAvailable && username != _user!.username) {
          _errorMessage = 'Username is already taken';
          notifyListeners();
          return false;
        }
        updates['username'] = username.toLowerCase();
      }
      if (notificationsEnabled != null) {
        updates['notificationsEnabled'] = notificationsEnabled;
      }

      await _firebaseService.updateUser(_user!.id, updates);
      await _loadUser(_user!.id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  void _handleAuthError(FirebaseAuthException e) {
    _state = AuthState.error;
    
    switch (e.code) {
      case 'email-already-in-use':
        _errorMessage = 'This email is already registered. Please sign in.';
        break;
      case 'invalid-email':
        _errorMessage = 'Please enter a valid email address.';
        break;
      case 'wrong-password':
        _errorMessage = 'Incorrect password. Please try again.';
        break;
      case 'user-not-found':
        _errorMessage = 'No account found with this email.';
        break;
      case 'network-request-failed':
        _errorMessage = 'Network error. Please check your connection.';
        break;
      case 'too-many-requests':
        _errorMessage = 'Too many attempts. Please try again later.';
        break;
      case 'weak-password':
        _errorMessage = 'Password is too weak. Please use a stronger password.';
        break;
      default:
        _errorMessage = 'Error: $e';
    }
    
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_user != null) {
      await _loadUser(_user!.id);
    }
  }
}
