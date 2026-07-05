import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin-side Firestore/Auth wrapper. Reads and writes the same
/// collections the carpenter app uses (carpenters, orders, offers,
/// gifts, giftRedemptions, leads, notifications, pointsLedger) so both
/// apps stay in sync against one Firebase project.
class AdminFirebaseService {
  AdminFirebaseService._();
  static final AdminFirebaseService instance = AdminFirebaseService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<UserCredential> login(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Admin accounts are provisioned manually (Firebase Console ->
  /// Authentication -> Add user, then add a matching doc to the `admins`
  /// collection) -- NOT self-service from this login screen. This used to
  /// auto-create whatever email/password was typed in via
  /// createUserWithEmailAndPassword, which meant anyone who found the
  /// public URL could grant themselves an authenticated session with a
  /// single login attempt. Authentication alone was never the real gate
  /// anyway; being listed in `admins` is (see checkIsAdmin and
  /// firestore.rules' isAdmin()).
  Future<void> logout() => auth.signOut();

  bool get hasSession => auth.currentUser != null;

  /// firestore.rules lets a signed-in user read ONLY their own doc under
  /// `admins/{uid}` (never list or read anyone else's) and never write to
  /// it at all -- admin status is granted exclusively via the Firebase
  /// Console or Admin SDK. A permission-denied error here means "not an
  /// admin", same as a missing doc.
  Future<bool> checkIsAdmin(String uid) async {
    try {
      final doc = await db.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Same self-read-only allowlist pattern as [checkIsAdmin], for the
  /// order-creator role (`orderCreators/{uid}`). An order-creator can log
  /// party orders but sees nothing else in the console.
  Future<bool> checkIsOrderCreator(String uid) async {
    try {
      final doc = await db.collection('orderCreators').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConfig() =>
      db.collection('config').doc('rules').snapshots();

  // ----- Party orders (order-creator role + admin review) ------------------

  /// All party orders, for the admin review screen.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPartyOrders() =>
      db.collection('partyOrders').orderBy('createdAt', descending: true).snapshots();

  /// Only the party orders this order-creator logged. Sorted client-side
  /// (see the class-level note in AppState): a where()+orderBy() on
  /// different fields would need a composite index.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPartyOrdersBy(String uid) =>
      db.collection('partyOrders').where('createdBy', isEqualTo: uid).snapshots();

  Future<void> addPartyOrder({
    required String carpenterId,
    required String carpenterName,
    required String party,
    required int amount,
    required String createdBy,
    String? fileUrl,
    String? fileType,
  }) {
    return db.collection('partyOrders').add({
      'carpenterId': carpenterId,
      'carpenterName': carpenterName,
      'party': party,
      'amount': amount,
      'status': 'pending',
      'approvedAmount': 0,
      'payments': [],
      'createdBy': createdBy,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileType != null) 'fileType': fileType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creator edit, allowed only while still pending (rules enforce this too).
  Future<void> updatePartyOrder(
    String id, {
    required String carpenterId,
    required String carpenterName,
    required String party,
    required int amount,
    String? fileUrl,
    String? fileType,
  }) {
    return db.collection('partyOrders').doc(id).update({
      'carpenterId': carpenterId,
      'carpenterName': carpenterName,
      'party': party,
      'amount': amount,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileType != null) 'fileType': fileType,
    });
  }

  Future<void> approvePartyOrder(String id, int approvedAmount, {int commissionPercent = 10}) =>
      db.collection('partyOrders').doc(id).update({'status': 'approved', 'approvedAmount': approvedAmount, 'commissionPercent': commissionPercent});

  Future<void> completePartyOrder(String id) =>
      db.collection('partyOrders').doc(id).update({'status': 'completed'});

  /// Records a payment the party made and credits the carpenter the
  /// resulting points in the same transaction -- points, the pointsLedger
  /// entry, and the notification all land together or not at all, mirroring
  /// [_recalculatePoints]. Points are computed from the *paid* amount, not
  /// the order/approved amount, since the party can pay in instalments.
  Future<void> recordPartyPayment({
    required String orderId,
    required String carpenterId,
    required String party,
    required int amount,
    required int commissionPercent,
  }) async {
    final orderRef = db.collection('partyOrders').doc(orderId);
    await db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      final data = snap.data() ?? {};
      final approved = (data['approvedAmount'] is int) ? data['approvedAmount'] as int : 0;
      final existing = (data['payments'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      final paidSoFar = existing.fold<int>(0, (s, p) => s + ((p['amount'] is int) ? p['amount'] as int : 0));
      final remaining = (approved - paidSoFar).clamp(0, approved);
      final capped = amount > remaining ? remaining : amount;
      if (capped <= 0) return;
      final points = (capped * commissionPercent) ~/ 100;
      existing.add({'amount': capped, 'points': points});
      tx.update(orderRef, {'payments': existing});
      if (points > 0) {
        tx.update(db.collection('carpenters').doc(carpenterId), {
          'points': FieldValue.increment(points),
          'lifetimePoints': FieldValue.increment(points),
        });
        tx.set(db.collection('pointsLedger').doc(), {
          'carpenterId': carpenterId,
          'type': 'Earned',
          'desc': 'Payment received from $party',
          'points': points,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> saveConfig({required int pointRuleAmount, required int pointRulePoints, required int minRedeemPoints}) {
    return db.collection('config').doc('rules').set({
      'pointRuleAmount': pointRuleAmount,
      'pointRulePoints': pointRulePoints,
      'minRedeemPoints': minRedeemPoints,
    }, SetOptions(merge: true));
  }

  Future<void> saveLeadPointsRule({required int qualifiedPoints, required int convertedPoints}) {
    return db.collection('config').doc('rules').set({
      'leadPointsQualified': qualifiedPoints,
      'leadPointsConverted': convertedPoints,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCarpenters() =>
      db.collection('carpenters').snapshots();

  Future<void> approveCarpenter(String id) =>
      db.collection('carpenters').doc(id).update({'status': 'Approved'});

  Future<void> rejectCarpenter(String id) =>
      db.collection('carpenters').doc(id).update({'status': 'Rejected'});

  Future<void> setCarpenterTier(String id, String tier) =>
      db.collection('carpenters').doc(id).update({'tier': tier});

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrders() => db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<void> setOrderAmount(String orderId, int amount) =>
      db.collection('orders').doc(orderId).update({'amount': amount});

  /// Saves the admin-entered line items and recomputes amount as their
  /// sum. If the order is already Fulfilled, this also re-runs the
  /// points recalculation against the new amount -- previously, editing
  /// the price after marking an order Fulfilled didn't touch the
  /// carpenter's points at all, since crediting only ever fired on the
  /// status *transition*, not on amount changes.
  Future<void> setOrderItems(
    String orderId,
    List<Map<String, dynamic>> items,
    int amount, {
    required String carpenterId,
    required String status,
    required int pointRuleAmount,
    required int pointRulePoints,
  }) async {
    await db.collection('orders').doc(orderId).update({'items': items, 'amount': amount});
    await _recalculatePoints(
      orderId: orderId,
      carpenterId: carpenterId,
      status: status,
      amount: amount,
      pointRuleAmount: pointRuleAmount,
      pointRulePoints: pointRulePoints,
    );
  }

  Future<void> setOrderInvoice(String orderId, String invoiceUrl) =>
      db.collection('orders').doc(orderId).update({'invoiceUrl': invoiceUrl});

  Future<void> setOrderStatus({
    required String orderId,
    required String carpenterId,
    required String status,
    required int pointRuleAmount,
    required int pointRulePoints,
    required int orderAmount,
  }) async {
    await db.collection('orders').doc(orderId).update({'status': status});
    await _recalculatePoints(
      orderId: orderId,
      carpenterId: carpenterId,
      status: status,
      amount: orderAmount,
      pointRuleAmount: pointRuleAmount,
      pointRulePoints: pointRulePoints,
    );
  }

  /// Single source of truth for order points. Tracks how many points an
  /// order has already credited (`creditedPoints` on the order doc) and
  /// applies only the *difference* between that and what the order
  /// should be worth right now -- so it's correct no matter the order
  /// price changes before or after marking Fulfilled, or status moves
  /// back out of Fulfilled (which reverses the credit).
  Future<void> _recalculatePoints({
    required String orderId,
    required String carpenterId,
    required String status,
    required int amount,
    required int pointRuleAmount,
    required int pointRulePoints,
  }) async {
    final orderRef = db.collection('orders').doc(orderId);
    await db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      final creditedRaw = snap.data()?['creditedPoints'];
      final credited = creditedRaw is int ? creditedRaw : int.tryParse('$creditedRaw') ?? 0;
      // 'Delivered' also keeps the credit -- it comes after Fulfilled in
      // the order lifecycle, not a reversal of it. Previously only
      // 'Fulfilled' counted, so moving an order on to Delivered zeroed
      // the target and silently clawed back the carpenter's points.
      final credits = status == 'Fulfilled' || status == 'Delivered';
      final target = (credits && pointRuleAmount > 0) ? (amount ~/ pointRuleAmount) * pointRulePoints : 0;
      final delta = target - credited;
      if (delta == 0) return;

      tx.update(orderRef, {'creditedPoints': target});
      tx.update(db.collection('carpenters').doc(carpenterId), {
        'points': FieldValue.increment(delta),
        if (delta > 0) 'lifetimePoints': FieldValue.increment(delta),
      });
      tx.set(db.collection('pointsLedger').doc(), {
        'carpenterId': carpenterId,
        'type': delta > 0 ? 'Earned' : 'Adjusted',
        'desc': delta > 0 ? 'Order #$orderId' : 'Order #$orderId (price corrected)',
        'points': delta,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (delta > 0) {
        tx.set(db.collection('notifications').doc(), {
          'carpenterId': carpenterId,
          'title': 'Points credited',
          'body': '+$delta points for your order',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOffers() =>
      db.collection('offers').orderBy('createdAt', descending: true).snapshots();

  Future<void> addOffer({
    required String title,
    required String category,
    required String validTill,
    String description = '',
    String? bannerUrl,
    String? pdfUrl,
    List<String>? targetCarpenterIds,
  }) async {
    final offerRef = await db.collection('offers').add({
      'title': title,
      'category': category,
      'validTill': validTill,
      'description': description.isEmpty ? title : description,
      'status': 'Live',
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
      if (targetCarpenterIds != null && targetCarpenterIds.isNotEmpty) 'targetCarpenterIds': targetCarpenterIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Targeted offers only notify the selected carpenters, regardless of
    // their approval status (an offer picked for a specific carpenter is
    // an explicit admin choice); untargeted offers go to everyone approved.
    final recipientIds = targetCarpenterIds != null && targetCarpenterIds.isNotEmpty
        ? targetCarpenterIds
        : (await db.collection('carpenters').where('status', isEqualTo: 'Approved').get()).docs.map((d) => d.id).toList();
    final batch = db.batch();
    for (final id in recipientIds) {
      batch.set(db.collection('notifications').doc(), {
        'carpenterId': id,
        'title': 'New offer',
        'body': '$title is now live!',
        'type': 'offer',
        'refId': offerRef.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Soft delete: marks the offer Withdrawn instead of removing the doc,
  /// so it still shows up in the admin's "Past offers" section and any
  /// existing carpenter-app references (e.g. a notification deep link)
  /// don't 404. The carpenter app's offer list filters out non-Live offers.
  Future<void> withdrawOffer(String id) => db.collection('offers').doc(id).update({'status': 'Withdrawn'});

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGifts() => db.collection('gifts').snapshots();

  Future<void> addGift({required String name, required int points, required int qty, String? imageUrl, String description = ''}) {
    return db.collection('gifts').add({
      'name': name,
      'description': description,
      'status': 'Live',
      'points': points,
      'qty': qty,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
  }

  /// Soft delete, same reasoning as withdrawOffer -- a withdrawn gift
  /// stops showing in the carpenter app's catalog but stays visible to
  /// the admin (and any already-redeemed history keeps working).
  Future<void> withdrawGift(String id) => db.collection('gifts').doc(id).update({'status': 'Withdrawn'});

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRedemptions() => db
      .collection('giftRedemptions')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<void> setRedemptionStatus({required String id, required String carpenterId, required String status}) async {
    final batch = db.batch();
    batch.update(db.collection('giftRedemptions').doc(id), {'status': status});
    batch.set(db.collection('notifications').doc(), {
      'carpenterId': carpenterId,
      'title': 'Redemption update',
      'body': 'Your redemption status is now $status',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLeads() =>
      db.collection('leads').orderBy('createdAt', descending: true).snapshots();

  /// Awards points for a lead reaching Qualified or Converted, tracked via
  /// `pointsAwarded` on the lead doc. `pointsAwarded` always reflects the
  /// total credited so far: going Qualified -> Converted tops up the
  /// *difference* (since Converted is the higher terminal stage), rather
  /// than being blocked by an "already awarded" check -- which is what
  /// silently ate the Converted bonus before.
  Future<void> setLeadStatus({
    required String id,
    required String carpenterId,
    required String status,
    required int qualifiedPoints,
    required int convertedPoints,
  }) async {
    final leadRef = db.collection('leads').doc(id);
    await leadRef.update({'status': status});
    final target = status == 'Converted' ? convertedPoints : (status == 'Qualified' ? qualifiedPoints : 0);
    if (target <= 0) return;
    await db.runTransaction((tx) async {
      final snap = await tx.get(leadRef);
      final already = snap.data()?['pointsAwarded'];
      final awarded = already is int ? already : int.tryParse('$already') ?? 0;
      final delta = target - awarded;
      if (delta <= 0) return; // this stage's rule isn't higher than what's already credited
      tx.update(leadRef, {'pointsAwarded': target});
      tx.update(db.collection('carpenters').doc(carpenterId), {
        'points': FieldValue.increment(delta),
        'lifetimePoints': FieldValue.increment(delta),
      });
      tx.set(db.collection('pointsLedger').doc(), {
        'carpenterId': carpenterId,
        'type': 'Earned',
        'desc': 'Lead $status bonus',
        'points': delta,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(db.collection('notifications').doc(), {
        'carpenterId': carpenterId,
        'title': 'Points credited',
        'body': '+$delta points for your lead reaching $status',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// [tier] is 'All' or one of carpenterTiers -- restricts the fan-out to
  /// only carpenters assigned that tier. Also logs to a persistent
  /// `broadcasts` collection so past sends survive a page reload (the
  /// previous version kept this in a local, ephemeral list only).
  Future<void> broadcastNotification(String title, String body, String tier) async {
    Query<Map<String, dynamic>> query = db.collection('carpenters').where('status', isEqualTo: 'Approved');
    if (tier != 'All') {
      query = query.where('tier', isEqualTo: tier);
    }
    final carpenters = await query.get();
    final batch = db.batch();
    for (final c in carpenters.docs) {
      batch.set(db.collection('notifications').doc(), {
        'carpenterId': c.id,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(db.collection('broadcasts').doc(), {
      'title': title,
      'body': body,
      'tier': tier,
      'recipientCount': carpenters.docs.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBroadcasts() =>
      db.collection('broadcasts').orderBy('createdAt', descending: true).limit(50).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAppVersion() =>
      db.collection('config').doc('appVersion').snapshots();

  Future<void> saveAppVersion({
    required String version,
    required int buildNumber,
    required String downloadUrl,
    String releaseNotes = '',
    bool forceUpdate = false,
  }) {
    return db.collection('config').doc('appVersion').set({
      'version': version,
      'buildNumber': buildNumber,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'forceUpdate': forceUpdate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
