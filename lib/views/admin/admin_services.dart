import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Check if the current user is an admin
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Fetch flagged businesses
  static Stream<QuerySnapshot> getFlaggedBusinesses() {
    return _firestore
        .collection('businesses')
        .where('flags', isGreaterThan: 0)
        .orderBy('flags', descending: true)
        .snapshots();
  }

  // Fetch flagged reviews
  static Stream<QuerySnapshot> getFlaggedReviews() {
    return _firestore
        .collectionGroup('reviews')
        .where('flags', isGreaterThan: 0)
        .orderBy('flags', descending: true)
        .snapshots();
  }

  // Fetch flagged users
  static Stream<QuerySnapshot> getFlaggedUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('totalFlagsReceived',
            isGreaterThan: 1) // Show users who flagged more than 3 times
        .snapshots();
  }

  // Delete a business
  static Future<void> deleteBusiness(String businessId) async {
    await _firestore.collection('businesses').doc(businessId).delete();
  }

  // Delete a review
  static Future<void> deleteReview(String reviewId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }

  // Delete a user
  static Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // Logout the current user
  static Future<void> logout() async {
    await _auth.signOut();
  }
}
