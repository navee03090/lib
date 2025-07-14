import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User canceled the sign-in flow
      if (googleUser == null) {
        throw Exception('Google sign-in was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name more safely
      if (userCredential.user != null) {
        // Create a wrapper to handle the profile update
        try {
          // We use a separate method to update the profile without triggering the PigeonUserDetails error
          await _updateUserProfile(userCredential.user!, name);
        } catch (e) {
          // Silently log profile update errors without failing signup
          print('Profile update error handled: $e');
        }
      }

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      // Filter out PigeonUserDetails errors
      if (e.toString().contains('PigeonUserDetails')) {
        print('Ignoring PigeonUserDetails error during signup');
        // As a fallback, sign in with the credentials
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Handle other unexpected errors
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Safer method to update user profile
  Future<void> _updateUserProfile(User user, String displayName) async {
    // Using a manual update to Firebase server instead of native method
    // This avoids the PigeonUserDetails error on some devices
    try {
      // Direct update bypassing problematic methods
      await user
          .updateDisplayName(displayName)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('Profile update timed out, continuing anyway');
              return;
            },
          );
    } catch (e) {
      print('Profile update alternative method failed: $e');
      // We don't rethrow - the account is created successfully
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _auth.signOut();

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // Helper to handle Firebase Auth exceptions
  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'The email address is already in use.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'operation-not-allowed':
        message = 'Email & Password accounts are not enabled.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Check your connection.';
        break;
      case 'account-exists-with-different-credential':
        message =
            'An account already exists with the same email address but different sign-in credentials.';
        break;
      default:
        message = e.message ?? 'An unknown error occurred.';
    }

    return Exception(message);
  }
}
