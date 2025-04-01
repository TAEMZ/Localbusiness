import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<UserModel?> signUp(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      // Save user details in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': role,
          'created_at': FieldValue.serverTimestamp(),
        });

        return UserModel(uid: user.uid, email: email, role: role);
      }
    } catch (e) {
      print('Sign Up Error: $e');
    }
    return null;
  }

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Fetch user role from Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final data = userDoc.data();
        print("uid${user.uid}");
        if (data != null) {
          return UserModel(
            uid: user.uid,
            email: data['email'],
            role: data['role'],
          );
        }
      }
    } catch (e) {
      print('Login Error: $e');
    }

    return null;
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
    } catch (e) {
      print('Reset Password Error: $e');
      rethrow;
    }
  }

  // Google Sign-In
  Future<UserModel?> signInWithGoogle(String role) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'role': role, // Use the passed role instead of hardcoding 'user'
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        return UserModel(uid: user.uid, email: user.email!, role: role);
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
    }
    return null;
  }

  Future<UserModel?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;

      final Map<String, dynamic> userData =
          await FacebookAuth.instance.getUserData();
      final String? accessToken = result.accessToken?.tokenString;

      if (accessToken == null) return null; // User canceled login

      final OAuthCredential credential =
          FacebookAuthProvider.credential(accessToken);

      UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = authResult.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'role': 'user',
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        return UserModel(uid: user.uid, email: user.email!, role: 'user');
      }
    } catch (e) {
      print('Facebook Sign-In Error: $e');
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout Error: $e');
    }
  }
}
