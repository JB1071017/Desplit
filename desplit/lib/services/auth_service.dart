import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'desktop_auth_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase initialization warning: $e');
    }
  }

  // Email & Password Sign In
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (username != null && username.trim().isNotEmpty) {
      await credential.user?.updateDisplayName(username.trim());
    }

    return credential;
  }


  void cancelDesktopAuth() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      DesktopAuthService.instance.cancelActiveAuth();
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return await _auth.signInWithPopup(googleProvider);
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return await DesktopAuthService.instance.signInWithGoogle();
    } else {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return await _auth.signInWithProvider(googleProvider);
    }
  }

  // GitHub Sign In
  Future<UserCredential?> signInWithGitHub() async {
    if (kIsWeb) {
      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');
      return await _auth.signInWithPopup(githubProvider);
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return await DesktopAuthService.instance.signInWithGitHub();
    } else {
      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('read:user');
      githubProvider.addScope('user:email');
      return await _auth.signInWithProvider(githubProvider);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper to translate FirebaseAuthException into clean, short UI text
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'operation-not-allowed':
          return 'Sign-in method is not enabled in Firebase Console.';
        case 'popup-closed-by-user':
          return 'Authentication window was closed.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error.toString();
  }
}
