import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'push_service.dart';

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
    required int rewardAmount,
    required int rewardPercent,
    required String createdBy,
    String? fileUrl,
    String? fileType,
  }) {
    return db.collection('partyOrders').add({
      'carpenterId': carpenterId,
      'carpenterName': carpenterName,
      'party': party,
      'amount': amount,
      'rewardAmount': rewardAmount,
      'rewardPercent': rewardPercent,
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
    required int rewardAmount,
    required int rewardPercent,
    String? fileUrl,
    String? fileType,
  }) {
    return db.collection('partyOrders').doc(id).update({
      'carpenterId': carpenterId,
      'carpenterName': carpenterName,
      'party': party,
      'amount': amount,
      'rewardAmount': rewardAmount,
      'rewardPercent': rewardPercent,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileType != null) 'fileType': fileType,
    });
  }

  /// Approval settles how much is collectable and is also the admin's last
  /// chance to correct the reward terms the creator entered -- once approved,
  /// the rules freeze them for the payment stage.
  Future<void> approvePartyOrder(String id, int approvedAmount, {required int rewardAmount, required int rewardPercent}) =>
      db.collection('partyOrders').doc(id).update({
        'status': 'approved',
        'approvedAmount': approvedAmount,
        'rewardAmount': rewardAmount,
        'rewardPercent': rewardPercent,
      });

  Future<void> completePartyOrder(String id) =>
      db.collection('partyOrders').doc(id).update({'status': 'completed'});

  /// Records a payment the party made and credits the carpenter the
  /// resulting points in the same transaction -- points, the pointsLedger
  /// entry, and the notification all land together or not at all, mirroring
  /// [_recalculatePoints].
  ///
  /// [pointsFor] scores this payment on its own -- its share of the reward
  /// amount, times reward % (see PartyOrder.pointsForPayment) -- so every
  /// entry in the history carries its own calculation.
  Future<void> recordPartyPayment({
    required String orderId,
    required String carpenterId,
    required String party,
    required int amount,
    required int Function(int payment) pointsFor,
    required int collectableAmount,
  }) async {
    final orderRef = db.collection('partyOrders').doc(orderId);
    var pushPoints = 0;
    await db.runTransaction((tx) async {
      pushPoints = 0;
      final snap = await tx.get(orderRef);
      final data = snap.data() ?? {};
      final existing = (data['payments'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      final paidSoFar = existing.fold<int>(0, (s, p) => s + ((p['amount'] is int) ? p['amount'] as int : 0));
      final remaining = (collectableAmount - paidSoFar).clamp(0, collectableAmount);
      final capped = amount > remaining ? remaining : amount;
      if (capped <= 0) return;
      final points = pointsFor(capped);
      existing.add({'amount': capped, 'points': points, 'at': DateTime.now()});
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
        tx.set(db.collection('notifications').doc(), {
          'carpenterId': carpenterId,
          'title': 'Points credited',
          'body': '+$points points added',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        pushPoints = points;
      }
    });
    if (pushPoints > 0) {
      await AdminPushService.instance.notify(
        carpenterIds: [carpenterId],
        title: 'Points credited',
        body: '+$pushPoints points added',
      );
    }
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
      db.collection('carpenters').limit(500).snapshots();

  Future<void> approveCarpenter(String id) =>
      db.collection('carpenters').doc(id).update({'status': 'Approved'});

  Future<void> rejectCarpenter(String id) =>
      db.collection('carpenters').doc(id).update({'status': 'Rejected'});

  Future<void> setCarpenterTier(String id, String tier) =>
      db.collection('carpenters').doc(id).update({'tier': tier});

  Future<void> triggerPinReset(String id) =>
      db.collection('carpenters').doc(id).update({'resetPin': true, 'pinSet': false, 'pinHash': FieldValue.delete()});

  Future<void> triggerPasswordReset(String id) =>
      db.collection('carpenters').doc(id).update({'resetPassword': true});

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrders() => db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(500)
      .snapshots();

  Future<void> setOrderAmount(String orderId, int amount) =>
      db.collection('orders').doc(orderId).update({'amount': amount});

  /// Saves the admin-entered order details (amount, hand-calculated
  /// points, and the party the goods came from). If the order is already
  /// Fulfilled, this also re-runs the points recalculation against the
  /// new points figure -- previously, editing the price after marking an
  /// order Fulfilled didn't touch the carpenter's points at all, since
  /// crediting only ever fired on the status *transition*.
  Future<void> setOrderDetails(
    String orderId, {
    required int amount,
    required int points,
    required String partyName,
    required String partyPhone,
    required String carpenterId,
    required String status,
  }) async {
    await db.collection('orders').doc(orderId).update({
      'amount': amount,
      'points': points,
      'partyName': partyName,
      'partyPhone': partyPhone,
    });
    await _recalculatePoints(
      orderId: orderId,
      carpenterId: carpenterId,
      status: status,
      points: points,
    );
  }

  Future<void> setOrderInvoice(String orderId, String invoiceUrl) =>
      db.collection('orders').doc(orderId).update({'invoiceUrl': invoiceUrl});

  Future<void> setOrderStatus({
    required String orderId,
    required String carpenterId,
    required String status,
    required int orderPoints,
  }) async {
    await db.collection('orders').doc(orderId).update({'status': status});
    await _recalculatePoints(
      orderId: orderId,
      carpenterId: carpenterId,
      status: status,
      points: orderPoints,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrderComments(String orderId) =>
      db.collection('orders').doc(orderId).collection('comments').orderBy('createdAt').snapshots();

  /// Posts an admin comment on an order and notifies the carpenter in the
  /// same batch, so the thread entry and its notification land together.
  Future<void> addOrderComment({
    required String orderId,
    required String carpenterId,
    required String orderNumber,
    required String text,
  }) async {
    final batch = db.batch();
    batch.set(db.collection('orders').doc(orderId).collection('comments').doc(), {
      'text': text,
      'authorRole': 'admin',
      'authorName': 'Admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('notifications').doc(), {
      'carpenterId': carpenterId,
      'title': 'New comment on your order',
      'body': 'Admin commented on order $orderNumber',
      'type': 'order',
      'refId': orderId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await AdminPushService.instance.notify(
      carpenterIds: [carpenterId],
      title: 'New comment on your order',
      body: 'Admin commented on order $orderNumber',
      type: 'order',
      refId: orderId,
    );
  }

  /// Single source of truth for order points. Tracks how many points an
  /// order has already credited (`creditedPoints` on the order doc) and
  /// applies only the *difference* between that and what the order
  /// should be worth right now -- so it's correct no matter whether the
  /// points figure changes before or after marking Fulfilled, or status
  /// moves back out of Fulfilled (which reverses the credit).
  ///
  /// [points] is the figure the admin typed on the order detail screen.
  /// Regular orders deliberately ignore the amount -> points config rule
  /// (that rule still governs party orders); for the MVP the points are
  /// calculated by hand and entered directly.
  Future<void> _recalculatePoints({
    required String orderId,
    required String carpenterId,
    required String status,
    required int points,
  }) async {
    final orderRef = db.collection('orders').doc(orderId);
    var pushDelta = 0;
    await db.runTransaction((tx) async {
      // Reset per attempt -- a retried transaction re-runs this whole body.
      pushDelta = 0;
      final snap = await tx.get(orderRef);
      final creditedRaw = snap.data()?['creditedPoints'];
      final credited = creditedRaw is int ? creditedRaw : int.tryParse('$creditedRaw') ?? 0;
      // 'Delivered' also keeps the credit -- it comes after Fulfilled in
      // the order lifecycle, not a reversal of it. Previously only
      // 'Fulfilled' counted, so moving an order on to Delivered zeroed
      // the target and silently clawed back the carpenter's points.
      final credits = status == 'Fulfilled' || status == 'Delivered';
      final target = credits ? points : 0;
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
        pushDelta = delta;
      }
    });
    // Outside the transaction: it can be retried by Firestore, and a
    // retried push would notify the carpenter twice for one credit.
    if (pushDelta > 0) {
      await AdminPushService.instance.notify(
        carpenterIds: [carpenterId],
        title: 'Points credited',
        body: '+$pushDelta points for your order',
        type: 'order',
        refId: orderId,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOffers() =>
      db.collection('offers').orderBy('createdAt', descending: true).limit(200).snapshots();

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
    await AdminPushService.instance.notify(
      carpenterIds: recipientIds,
      title: 'New offer',
      body: '$title is now live!',
      type: 'offer',
      refId: offerRef.id,
    );
  }

  /// Soft delete: marks the offer Withdrawn instead of removing the doc,
  /// so it still shows up in the admin's "Past offers" section and any
  /// existing carpenter-app references (e.g. a notification deep link)
  /// don't 404. The carpenter app's offer list filters out non-Live offers.
  Future<void> withdrawOffer(String id) => db.collection('offers').doc(id).update({'status': 'Withdrawn'});

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGifts() => db.collection('gifts').limit(200).snapshots();

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
      .limit(500)
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
    await AdminPushService.instance.notify(
      carpenterIds: [carpenterId],
      title: 'Redemption update',
      body: 'Your redemption status is now $status',
    );
  }

  /// Problems reported from the carpenter app's Feedback screen.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchFeedback() =>
      db.collection('feedback').orderBy('createdAt', descending: true).limit(500).snapshots();

  Future<void> setFeedbackStatus(String id, String status) =>
      db.collection('feedback').doc(id).update({'status': status});

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLeads() =>
      db.collection('leads').orderBy('createdAt', descending: true).limit(500).snapshots();

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
    await AdminPushService.instance.notify(
      carpenterIds: carpenters.docs.map((c) => c.id).toList(),
      title: title,
      body: body,
    );
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
