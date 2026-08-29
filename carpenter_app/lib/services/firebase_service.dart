import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firestore/Auth so the rest of the app never imports
/// the Firebase SDK directly. Collections mirror the PRD's data model
/// (section 22): carpenters, orders, offers, gifts, giftRedemptions, leads,
/// notifications, pointsLedger.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  User? get currentUser => auth.currentUser;

  /// [authEmail] is the address Firebase Auth signs the account in with;
  /// [email] is the carpenter's own address for their profile, which is
  /// empty when they didn't give one. The two differ for mobile-only
  /// accounts, where authEmail is synthesized from the mobile number
  /// (see mobileAuthEmail in app_state.dart) -- storing that synthetic
  /// address on the profile would show the admin console a contact
  /// address that doesn't exist.
  Future<UserCredential> registerCarpenter({
    required String authEmail,
    required String password,
    required String name,
    required String mobile,
    required String shop,
    required String address,
    String email = '',
    String? photoUrl,
    String? pinHash,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(email: authEmail, password: password);
    await db.collection('carpenters').doc(cred.user!.uid).set({
      'name': name,
      'mobile': mobile,
      'shop': shop,
      'address': address,
      'email': email,
      'status': 'Pending',
      'points': 0,
      'lifetimePoints': 0,
      'redeemedPoints': 0,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (pinHash != null) 'pinHash': pinHash,
      'pinSet': pinHash != null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> login(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => auth.signOut();

  DocumentReference<Map<String, dynamic>> carpenterDoc(String uid) =>
      db.collection('carpenters').doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCarpenter(String uid) =>
      carpenterDoc(uid).snapshots();

  /// Device tokens for push, kept as a list because one carpenter can
  /// have the app on more than one handset. arrayUnion means re-saving
  /// the same token on every launch is a no-op.
  Future<void> addFcmToken(String carpenterId, String token) => carpenterDoc(carpenterId)
      .set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));

  Future<void> removeFcmToken(String carpenterId, String token) => carpenterDoc(carpenterId)
      .set({'fcmTokens': FieldValue.arrayRemove([token])}, SetOptions(merge: true));

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOffers() =>
      db.collection('offers').orderBy('createdAt', descending: true).limit(200).snapshots();

  // NOTE: deliberately no .orderBy() chained onto these where() queries.
  // Firestore requires a manual composite index for where+orderBy on
  // different fields; without it the query throws and (since nothing
  // attaches an onError handler upstream) just looks like "nothing
  // happens". Sorting is done client-side in AppState instead.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrders(String carpenterId) =>
      db.collection('orders').where('carpenterId', isEqualTo: carpenterId).snapshots();

  /// Generates human-readable, atomically-incrementing order numbers like
  /// "OD-0001" via a counter doc + transaction, so concurrent orders from
  /// different carpenters never collide. The Firestore-assigned doc ID
  /// stays the real reference used for status/amount updates; orderNumber
  /// is purely for display.
  Future<void> addOrder(String carpenterId, Map<String, dynamic> data) async {
    final orderRef = db.collection('orders').doc();
    final counterRef = db.collection('counters').doc('orders');
    await db.runTransaction((tx) async {
      final counterSnap = await tx.get(counterRef);
      final next = ((counterSnap.data()?['count'] as int?) ?? 0) + 1;
      tx.set(counterRef, {'count': next});
      tx.set(orderRef, {
        ...data,
        'carpenterId': carpenterId,
        'status': 'Submitted',
        'points': 0,
        'orderNumber': 'OD-${next.toString().padLeft(4, '0')}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Per-order comment thread with the admin. Rules only allow reading /
  /// replying on the carpenter's own orders, and replies must carry
  /// authorRole 'carpenter'.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrderComments(String orderId) =>
      db.collection('orders').doc(orderId).collection('comments').orderBy('createdAt').snapshots();

  Future<void> addOrderComment(String orderId, {required String authorName, required String text}) =>
      db.collection('orders').doc(orderId).collection('comments').add({
        'text': text,
        'authorRole': 'carpenter',
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGifts() =>
      db.collection('gifts').limit(200).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRedemptions(String carpenterId) =>
      db.collection('giftRedemptions').where('carpenterId', isEqualTo: carpenterId).snapshots();

  /// Lets the carpenter self-confirm they received a gift/cash redemption.
  /// Writes to the same document the admin Redemptions screen reads, so
  /// both sides see the same status live.
  Future<void> markRedemptionDelivered(String redemptionId) =>
      db.collection('giftRedemptions').doc(redemptionId).update({'status': 'Delivered'});

  Future<void> redeemGift({
    required String carpenterId,
    required String giftId,
    required String giftName,
    required int points,
  }) {
    final batch = db.batch();
    final carpenterRef = carpenterDoc(carpenterId);
    final giftRef = db.collection('gifts').doc(giftId);
    final redemptionRef = db.collection('giftRedemptions').doc();
    batch.update(carpenterRef, {
      'points': FieldValue.increment(-points),
      'redeemedPoints': FieldValue.increment(points),
    });
    batch.update(giftRef, {'qty': FieldValue.increment(-1)});
    batch.set(redemptionRef, {
      'carpenterId': carpenterId,
      'type': 'Gift',
      'giftId': giftId,
      'giftName': giftName,
      'points': points,
      'status': 'Ordered',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('pointsLedger').doc(), {
      'carpenterId': carpenterId,
      'type': 'Redeemed',
      'desc': 'Gift Redemption: $giftName',
      'points': -points,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  /// Cash redemptions go through the same giftRedemptions collection
  /// (type: 'Cash') so admin sees one unified queue with the same
  /// Ordered -> In store -> Delivered status flow as physical gifts.
  Future<void> redeemCash(String carpenterId, int amount) {
    final batch = db.batch();
    final redemptionRef = db.collection('giftRedemptions').doc();
    batch.update(carpenterDoc(carpenterId), {
      'points': FieldValue.increment(-amount),
      'redeemedPoints': FieldValue.increment(amount),
    });
    batch.set(redemptionRef, {
      'carpenterId': carpenterId,
      'type': 'Cash',
      'giftName': 'Cash (Rs $amount)',
      'points': amount,
      'status': 'Ordered',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('pointsLedger').doc(), {
      'carpenterId': carpenterId,
      'type': 'Redeemed',
      'desc': 'Redeemed as cash',
      'points': -amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPointsLedger(String carpenterId) =>
      db.collection('pointsLedger').where('carpenterId', isEqualTo: carpenterId).limit(500).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLeaderboard() =>
      db.collection('carpenters').where('status', isEqualTo: 'Approved').orderBy('points', descending: true).limit(10).snapshots();

  Future<void> addLead(String carpenterId, Map<String, dynamic> data) {
    return db.collection('leads').add({
      ...data,
      'carpenterId': carpenterId,
      'status': 'New',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Carpenter-reported problems for the admin to act on. Any mix of
  /// typed text, a voice note and a photo -- carpenters who can't read
  /// or write comfortably use the other two.
  Future<void> addFeedback(String carpenterId, Map<String, dynamic> data) {
    return db.collection('feedback').add({
      ...data,
      'carpenterId': carpenterId,
      'status': 'New',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLeads(String carpenterId) =>
      db.collection('leads').where('carpenterId', isEqualTo: carpenterId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications(String carpenterId) =>
      db.collection('notifications').where('carpenterId', isEqualTo: carpenterId).limit(200).snapshots();

  Future<void> deleteNotifications(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    final batch = db.batch();
    for (final id in notificationIds) {
      batch.delete(db.collection('notifications').doc(id));
    }
    await batch.commit();
  }

  Future<void> savePayoutDetails(String carpenterId, Map<String, dynamic> data) {
    return carpenterDoc(carpenterId).set({'payout': data}, SetOptions(merge: true));
  }

  /// Reports the carpenter's current position for the admin Locations map.
  /// Only runs while the app is open (foreground) -- see geolocator usage
  /// in AppState for the permission flow.
  Future<void> updateLocation(String carpenterId, double lat, double lng) {
    return carpenterDoc(carpenterId).set({
      'location': {'lat': lat, 'lng': lng},
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile(String carpenterId, Map<String, dynamic> data) {
    return carpenterDoc(carpenterId).set(data, SetOptions(merge: true));
  }

  Future<void> reportAnalytics(String carpenterId, {required String appVersion, required int buildNumber}) {
    return carpenterDoc(carpenterId).set({
      'lastLogin': FieldValue.serverTimestamp(),
      'appVersion': appVersion,
      'appBuildNumber': buildNumber,
      'isOnline': true,
      'platform': 'android',
      'loginCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> setOnlineStatus(String carpenterId, bool online) {
    return carpenterDoc(carpenterId).set({
      'isOnline': online,
      if (!online) 'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setPin(String carpenterId, String pinHash) {
    return carpenterDoc(carpenterId).set({
      'pinHash': pinHash,
      'pinSet': true,
      'resetPin': false,
    }, SetOptions(merge: true));
  }

  Future<void> clearResetPassword(String carpenterId) {
    return carpenterDoc(carpenterId).set({
      'resetPassword': false,
    }, SetOptions(merge: true));
  }

  /// Admin-editable rules (points-per-rupee, minimum cash redemption).
  /// Single doc so both apps share one source of truth.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConfig() =>
      db.collection('config').doc('rules').snapshots();
}
