import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final Rx<User?> _user = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isAuthenticated = false.obs;
  final RxString _userType = 'renter'.obs;
  final RxMap<String, dynamic> _userProfile = <String, dynamic>{}.obs;

  // Getters
  User? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  String get userType => _userType.value;
  Map<String, dynamic> get userProfile => _userProfile.value;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    ever(_user, (User? user) {
      _isAuthenticated.value = user != null;
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile.clear();
        _userType.value = 'renter';
      }
    });

    // Set initial user
    _user.value = _auth.currentUser;
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_user.value == null) return;

    try {
      final doc =
          await _firestore.collection('users').doc(_user.value!.uid).get();

      if (doc.exists) {
        _userProfile.value = doc.data()!;
        _userType.value = doc.data()!['userType'] ?? 'renter';
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailPassword(
      String email, String password, String fullName) async {
    try {
      _isLoading.value = true;
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, 'renter');

      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading.value = true;

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Get.snackbar('Error', 'Google sign in aborted');
        return false;
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

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!, 'renter');
      }

      return true;
    } catch (e) {
      if (e is FirebaseAuthException) {
        _handleAuthException(e);
      } else {
        Get.snackbar('Error', 'Failed to sign in with Google: ${e.toString()}');
      }
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      await _googleSignIn.signOut();
      await _auth.signOut();
      Get.offAllNamed('/');
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: ${e.toString()}');
    } finally {
      _isLoading.value = false;
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

  // Handle Firebase Auth exceptions
  void _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = 'Authentication failed: ${e.message}';
    }
    Get.snackbar('Authentication Error', message);
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_user.value == null) return;

    try {
      await _firestore.collection('users').doc(_user.value!.uid).update({
        ...data,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      await _loadUserProfile();
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    }
  }

  // Update user type
  Future<void> updateUserType(String userType) async {
    await updateUserProfile({'userType': userType});
  }
}
