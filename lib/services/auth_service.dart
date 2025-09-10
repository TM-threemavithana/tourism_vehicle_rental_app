import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // If you still have issues, uncomment the line below with your web client ID
    clientId: '921265432897-ifmr0kaut4fbdnuimokro90i76nfbv4l.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailPassword(
      String email, String password, String fullName) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Create user document in Firestore with default userType as 'renter'
      await _createUserDocument(userCredential.user!, 'renter');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in aborted');
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

      // Check if this is a new user (first time sign in)
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create user document with default userType
        await _createUserDocument(userCredential.user!, 'renter');
      }

      return userCredential;
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw _handleAuthException(e);
      }
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      // Check if Apple Sign In is available (iOS 13+, macOS 10.15+)
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential from the Apple credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // For Apple Sign In, we might need to get the display name from the credential
      // since Apple only provides the name on the first sign in
      String? displayName = userCredential.user?.displayName;
      if (displayName == null || displayName.isEmpty) {
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      // Check if this is a new user (first time sign in)
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create user document with default userType
        await _createUserDocument(userCredential.user!, 'renter');
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          throw Exception('Apple Sign In was canceled');
        case AuthorizationErrorCode.failed:
          throw Exception('Apple Sign In failed. Please check your Apple ID configuration and try again.');
        case AuthorizationErrorCode.invalidResponse:
          throw Exception('Invalid response from Apple. Please try again.');
        case AuthorizationErrorCode.notHandled:
          throw Exception('Apple Sign In not handled. Please try again.');
        case AuthorizationErrorCode.unknown:
          throw Exception('Unknown error occurred during Apple Sign In');
        default:
          throw Exception('Apple Sign In failed: ${e.message}');
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw _handleAuthException(e);
      }
      throw Exception('Failed to sign in with Apple: ${e.toString()}');
    }
  }

  // Create or update user document in Firestore
  Future<void> _createUserDocument(User user, String defaultUserType) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'userType': defaultUserType,
        'vehiclesRented': 0,
        'totalReviews': 0,
        'vehiclesListed': 0,
        'activeRentals': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update user type
  Future<void> updateUserType(String userType) async {
    if (currentUser == null) return;

    // First check if user document exists
    final userDoc =
        await _firestore.collection('users').doc(currentUser!.uid).get();

    if (!userDoc.exists) {
      // Create user document if it doesn't exist
      await _createUserDocument(currentUser!, userType);
    } else {
      // Update existing document
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'userType': userType,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get current user type
  Future<String> getUserType() async {
    if (currentUser == null) return 'renter';

    final userDoc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    if (userDoc.exists) {
      return userDoc.data()?['userType'] ?? 'renter';
    }

    return 'renter';
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = e.message ?? 'An unknown error occurred.';
    }
    return Exception(message);
  }
}
