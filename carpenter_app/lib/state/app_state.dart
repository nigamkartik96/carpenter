import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/background_location.dart';
import '../services/firebase_service.dart';

String initialsOf(String name) {
  final n = name.trim();
  if (n.isEmpty) return '?';
  return n.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
}

/// Firestore documents are untyped at the SDK level -- a document created
/// by hand in the console (or by a future app version) can easily store a
/// number as a string. `field ?? 0` only guards against null, not against
/// a wrong type, and a raw type-cast failure inside a stream listener's
/// callback throws *synchronously*, which is NOT caught by that
/// subscription's onError (onError only catches errors from the stream
/// itself) -- it becomes an uncaught Zone error that silently kills the
/// whole rebuild with no banner. Always parse numeric fields through this.
int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Central app state, backed by real Firebase Auth + Firestore.
/// Screens read the cached lists below; they're kept in sync via live
/// snapshot subscriptions started on login and cancelled on logout.
///
/// IMPORTANT: none of the per-carpenter queries below use Firestore's
/// orderBy() chained onto a where() filter on a different field --
/// that combination requires a manual composite index, and without one
/// the query throws an error that (if unhandled) just looks like
/// "nothing happens". Sorting is done client-side instead, after each
/// snapshot arrives. If you add a new where+orderBy query, either build
/// the composite index in the Firestore console or sort client-side too.
class AppState extends ChangeNotifier {
  final AppLocale locale = AppLocale(false);
  final FirebaseService _fb = FirebaseService.instance;

  String? uid;
  String carpenterName = '';
  String shopName = '';
  String mobile = '';
  String address = '';
  String status = 'Pending';
  String? photoUrl;
  String upiId = '';
  String bankName = '';
  String accountNumber = '';
  String ifsc = '';
  String? qrUrl;
  int points = 0;
  int lifetimePoints = 0;
  int redeemedPoints = 0;

  int pointRuleAmount = 100;
  int pointRulePoints = 1;
  int minRedeemPoints = 500;

  String? lastError;

  final List<LeaderboardEntry> leaderboard = [];
  final List<Offer> offers = [];
  final List<CarpenterOrder> orders = [];
  final List<Gift> gifts = [];
  final List<GiftRedemption> redemptions = [];
  final List<PointsLedgerEntry> ledger = [];
  final List<Lead> leads = [];
  final List<AppNotification> notifications = [];
  int get unreadCount => notifications.where((n) => !n.read).length;

  String tr(String key) => locale.tr(key);
  String trf(String key, Object n) => locale.trf(key, n);
  String get initials => initialsOf(carpenterName);

  double fontScale = 1.0;

  /// Loads the last-saved language and font scale before first frame, so
  /// re-opening the app doesn't flash back to English/default size.
  Future<void> loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      locale.isHindi = prefs.getBool('isHindi') ?? false;
      fontScale = prefs.getDouble('fontScale') ?? 1.0;
      notifyListeners();
    } catch (_) {
      // Best-effort -- fall back to defaults if prefs aren't available.
    }
  }

  void setLanguage(bool hindi) {
    locale.isHindi = hindi;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool('isHindi', hindi));
  }

  void setFontScale(double scale) {
    fontScale = scale;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setDouble('fontScale', scale));
  }

  final List<StreamSubscription> _subs = [];
  Timer? _locationTimer;

  bool get isLoggedIn => uid != null;
  bool get isApproved => status == 'Approved';

  /// Called once at app startup to resume an existing Firebase session
  /// instead of always showing the login screen.
  Future<bool> tryResumeSession() async {
    final user = _fb.currentUser;
    if (user == null) return false;
    final approved = await _refreshStatusOnce();
    if (approved) {
      await _startListening();
      startLocationReporting();
    }
    return true;
  }

  Future<String> register({
    required String name,
    required String mobileNum,
    required String email,
    required String password,
    required String shop,
    required String addr,
    String? photoUrl,
  }) async {
    try {
      await _fb.registerCarpenter(
        email: email,
        password: password,
        name: name,
        mobile: mobileNum,
        shop: shop,
        address: addr,
        photoUrl: photoUrl,
      );
      return 'ok';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    }
  }

  Future<String> login(String email, String password) async {
    try {
      final cred = await _fb.login(email, password);
      uid = cred.user!.uid;
      await _refreshStatusOnce();
      if (isApproved) {
        await _startListening();
        startLocationReporting();
      }
      return 'ok';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  /// Checks the current Firebase-authenticated user's Firestore status
  /// once (no live listener). Used on the pending-approval screen and
  /// right after login, before deciding whether to start full listeners.
  Future<bool> _refreshStatusOnce() async {
    final user = _fb.currentUser;
    if (user == null) return false;
    uid = user.uid;
    final doc = await _fb.carpenterDoc(user.uid).get();
    final d = doc.data();
    if (d == null) return false;
    carpenterName = d['name'] ?? '';
    shopName = d['shop'] ?? '';
    mobile = d['mobile'] ?? '';
    address = d['address'] ?? '';
    status = d['status'] ?? 'Pending';
    photoUrl = d['photoUrl'];
    final payout = d['payout'] as Map<String, dynamic>?;
    upiId = payout?['upiId'] ?? '';
    bankName = payout?['bankName'] ?? '';
    accountNumber = payout?['accountNumber'] ?? '';
    ifsc = payout?['ifsc'] ?? '';
    qrUrl = payout?['qrUrl'];
    points = _int(d['points']);
    lifetimePoints = _int(d['lifetimePoints']);
    redeemedPoints = _int(d['redeemedPoints']);
    notifyListeners();
    return isApproved;
  }

  /// Re-checks approval status (e.g. "Refresh status" button on the
  /// pending screen). Starts live listeners once approved.
  Future<bool> checkApproval() async {
    final approved = await _refreshStatusOnce();
    if (approved && _subs.isEmpty) await _startListening();
    return approved;
  }

  Future<void> logout() async {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _locationTimer?.cancel();
    _locationTimer = null;
    cancelBackgroundLocation().catchError((_) {});
    await _fb.logout();
    uid = null;
    carpenterName = '';
    points = 0;
    orders.clear();
    offers.clear();
    gifts.clear();
    redemptions.clear();
    ledger.clear();
    leads.clear();
    notifications.clear();
    leaderboard.clear();
    notifyListeners();
  }

  void _reportError(String where, Object e) {
    lastError = '$where: $e';
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  /// Best-effort: requests location permission if needed and reports the
  /// current position once, then every 5 minutes while the app stays
  /// open. Silently no-ops on denial or any platform error -- location
  /// is a nice-to-have for the admin map, never something that should
  /// block or error out the rest of the app.
  Future<void> reportLocationOnce() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (uid != null) await _fb.updateLocation(uid!, pos.latitude, pos.longitude);
    } catch (_) {
      // Best-effort -- a denied permission or a flaky GPS fix shouldn't
      // surface as an app-wide error banner.
    }
  }

  /// Called explicitly once the carpenter has seen and accepted the
  /// location-sharing rationale (ConsentScreen), or implicitly on
  /// subsequent logins/resumes where that consent was already given
  /// during the original approval flow.
  void startLocationReporting() {
    _locationTimer?.cancel();
    reportLocationOnce();
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) => reportLocationOnce());
    // Best-effort: if this fails (e.g. background location permission not
    // yet granted on Android 10+), foreground reporting above still works
    // whenever the carpenter has the app open.
    scheduleBackgroundLocation().catchError((_) {});
  }

  Future<void> _startListening() async {
    final id = uid!;

    _subs.add(_fb.watchCarpenter(id).listen((snap) {
      try {
        final d = snap.data();
        if (d == null) return;
        carpenterName = d['name'] ?? '';
        shopName = d['shop'] ?? '';
        mobile = d['mobile'] ?? '';
        address = d['address'] ?? '';
        status = d['status'] ?? 'Pending';
        photoUrl = d['photoUrl'];
        final payout = d['payout'] as Map<String, dynamic>?;
        upiId = payout?['upiId'] ?? '';
        bankName = payout?['bankName'] ?? '';
        accountNumber = payout?['accountNumber'] ?? '';
        ifsc = payout?['ifsc'] ?? '';
        qrUrl = payout?['qrUrl'];
        points = _int(d['points']);
        lifetimePoints = _int(d['lifetimePoints']);
        redeemedPoints = _int(d['redeemedPoints']);
        notifyListeners();
      } catch (e) {
        _reportError('carpenter', e);
      }
    }, onError: (e) => _reportError('carpenter', e)));

    _subs.add(_fb.watchConfig().listen((snap) {
      try {
        final d = snap.data();
        if (d == null) return;
        pointRuleAmount = _int(d['pointRuleAmount'], 100);
        pointRulePoints = _int(d['pointRulePoints'], 1);
        minRedeemPoints = _int(d['minRedeemPoints'], 500);
        notifyListeners();
      } catch (e) {
        _reportError('config', e);
      }
    }, onError: (e) => _reportError('config', e)));

    _subs.add(_fb.watchOffers().listen((snap) {
      try {
        final list = snap.docs.where((doc) {
          final d = doc.data();
          if ((d['status'] ?? 'Live') != 'Live') return false;
          // Offers targeted at specific carpenters (see admin's offer
          // form) only show for carpenters in that list; an absent or
          // empty list means "everyone".
          final targets = (d['targetCarpenterIds'] as List?)?.map((e) => '$e');
          return targets == null || targets.isEmpty || targets.contains(uid);
        }).map((doc) {
          final d = doc.data();
          return Offer(
            id: doc.id,
            title: d['title'] ?? '',
            description: d['description'] ?? '',
            category: d['category'] ?? 'Today',
            validTill: d['validTill'] ?? '',
            bannerUrl: d['bannerUrl'],
            pdfUrl: d['pdfUrl'],
          );
        });
        offers
          ..clear()
          ..addAll(list);
        notifyListeners();
      } catch (e) {
        _reportError('offers', e);
      }
    }, onError: (e) => _reportError('offers', e)));

    _subs.add(_fb.watchOrders(id).listen((snap) {
      try {
        final docs = snap.docs.toList()..sort((a, b) => _ts(b.data()['createdAt']).compareTo(_ts(a.data()['createdAt'])));
        orders
          ..clear()
          ..addAll(docs.map((doc) {
            final d = doc.data();
            final rawItems = d['items'];
            return CarpenterOrder(
              id: doc.id,
              type: d['type'] ?? 'Manual',
              detail: d['detail'] ?? '',
              status: d['status'] ?? 'Submitted',
              date: _fmtDate(d['createdAt']),
              points: _int(d['points']),
              imageUrl: d['imageUrl'],
              orderNumber: d['orderNumber'],
              invoiceUrl: d['invoiceUrl'],
              audioUrl: d['audioUrl'],
              items: rawItems is List ? rawItems.map((m) => OrderItem.fromMap(Map<String, dynamic>.from(m as Map))).toList() : const [],
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('orders', e);
      }
    }, onError: (e) => _reportError('orders', e)));

    _subs.add(_fb.watchGifts().listen((snap) {
      try {
        gifts
          ..clear()
          ..addAll(snap.docs.where((doc) => (doc.data()['status'] ?? 'Live') == 'Live').map((doc) {
            final d = doc.data();
            return Gift(
              id: doc.id,
              name: d['name'] ?? '',
              points: _int(d['points']),
              qty: _int(d['qty']),
              imageUrl: d['imageUrl'],
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('gifts', e);
      }
    }, onError: (e) => _reportError('gifts', e)));

    _subs.add(_fb.watchRedemptions(id).listen((snap) {
      try {
        final docs = snap.docs.toList()..sort((a, b) => _ts(b.data()['createdAt']).compareTo(_ts(a.data()['createdAt'])));
        redemptions
          ..clear()
          ..addAll(docs.map((doc) {
            final d = doc.data();
            return GiftRedemption(
              id: doc.id,
              giftName: d['giftName'] ?? '',
              points: _int(d['points']),
              date: _fmtDate(d['createdAt']),
              status: d['status'] ?? 'Pending',
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('redemptions', e);
      }
    }, onError: (e) => _reportError('redemptions', e)));

    _subs.add(_fb.watchPointsLedger(id).listen((snap) {
      try {
        final docs = snap.docs.toList()..sort((a, b) => _ts(b.data()['createdAt']).compareTo(_ts(a.data()['createdAt'])));
        ledger
          ..clear()
          ..addAll(docs.map((doc) {
            final d = doc.data();
            return PointsLedgerEntry(
              d['desc'] ?? '',
              _int(d['points']),
              _fmtDate(d['createdAt']),
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('pointsLedger', e);
      }
    }, onError: (e) => _reportError('pointsLedger', e)));

    _subs.add(_fb.watchLeads(id).listen((snap) {
      try {
        final docs = snap.docs.toList()..sort((a, b) => _ts(b.data()['createdAt']).compareTo(_ts(a.data()['createdAt'])));
        leads
          ..clear()
          ..addAll(docs.map((doc) {
            final d = doc.data();
            final loc = d['geo'] as Map<String, dynamic>?;
            return Lead(
              name: d['name'] ?? '',
              phone: d['phone'] ?? '',
              location: d['location'] ?? '',
              notes: d['notes'] ?? '',
              status: d['status'] ?? 'New',
              lat: loc != null ? (loc['lat'] as num?)?.toDouble() : null,
              lng: loc != null ? (loc['lng'] as num?)?.toDouble() : null,
              pointsAwarded: _int(d['pointsAwarded']),
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('leads', e);
      }
    }, onError: (e) => _reportError('leads', e)));

    _subs.add(_fb.watchNotifications(id).listen((snap) {
      try {
        final docs = snap.docs.toList()..sort((a, b) => _ts(b.data()['createdAt']).compareTo(_ts(a.data()['createdAt'])));
        notifications
          ..clear()
          ..addAll(docs.map((doc) {
            final d = doc.data();
            return AppNotification(
              doc.id,
              d['title'] ?? '',
              d['body'] ?? '',
              _fmtDate(d['createdAt']),
              read: d['read'] ?? true, // notifications created before this field existed default to read
              type: d['type'],
              refId: d['refId'],
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('notifications', e);
      }
    }, onError: (e) => _reportError('notifications', e)));

    _subs.add(_fb.watchLeaderboard().listen((snap) {
      try {
        final docs = snap.docs.toList()..sort((a, b) => _int(b.data()['points']).compareTo(_int(a.data()['points'])));
        leaderboard
          ..clear()
          ..addAll(docs.take(5).map((doc) {
            final d = doc.data();
            final n = (d['name'] ?? '?') as String;
            return LeaderboardEntry(initialsOf(n), n, _int(d['points']), photoUrl: d['photoUrl']);
          }));
        notifyListeners();
      } catch (e) {
        _reportError('leaderboard', e);
      }
    }, onError: (e) => _reportError('leaderboard', e)));
  }

  Timestamp _ts(dynamic v) => v is Timestamp ? v : Timestamp(0, 0);

  String _fmtDate(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return 'Today';
  }

  Future<void> addOrder(CarpenterOrder order, {String? imageUrl, String? audioUrl}) async {
    try {
      await _fb.addOrder(uid!, {
        'type': order.type,
        'detail': order.detail,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
      });
    } catch (e) {
      _reportError('addOrder', e);
      rethrow;
    }
  }

  /// Lets the carpenter self-confirm a gift/cash redemption was received.
  Future<void> markRedemptionDelivered(String redemptionId) async {
    try {
      await _fb.markRedemptionDelivered(redemptionId);
    } catch (e) {
      _reportError('markRedemptionDelivered', e);
      rethrow;
    }
  }

  /// Returns 'ok' on success, or a user-facing reason string otherwise.
  Future<String> redeemGift(Gift gift) async {
    if (points < gift.points) return 'Not enough points';
    if (gift.qty < 1) return 'Out of stock';
    try {
      await _fb.redeemGift(carpenterId: uid!, giftId: gift.id, giftName: gift.name, points: gift.points);
      return 'ok';
    } catch (e) {
      _reportError('redeemGift', e);
      return 'Redemption failed: $e';
    }
  }

  /// Returns 'ok' on success, or a user-facing reason string otherwise.
  Future<String> redeemCash(int amount) async {
    if (amount < minRedeemPoints) return 'Minimum $minRedeemPoints points required';
    if (points < amount) return 'Not enough points';
    try {
      await _fb.redeemCash(uid!, amount);
      return 'ok';
    } catch (e) {
      _reportError('redeemCash', e);
      return 'Redemption failed: $e';
    }
  }

  Future<void> addLead(Lead lead) async {
    try {
      await _fb.addLead(uid!, {
        'name': lead.name,
        'phone': lead.phone,
        'location': lead.location,
        'notes': lead.notes,
        if (lead.lat != null && lead.lng != null) 'geo': {'lat': lead.lat, 'lng': lead.lng},
      });
    } catch (e) {
      _reportError('addLead', e);
      rethrow;
    }
  }

  Future<void> savePayout(Map<String, String> data) async {
    await _fb.savePayoutDetails(uid!, data);
  }

  Future<void> markNotificationsRead() async {
    final unread = notifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    // Clear the bell badge immediately rather than waiting on the
    // Firestore round-trip -- the live listener reconciles this with
    // server state moments later anyway.
    for (final n in unread) {
      n.read = true;
    }
    notifyListeners();
    try {
      await _fb.markNotificationsRead(unread.map((n) => n.id).toList());
    } catch (e) {
      _reportError('markNotificationsRead', e);
    }
  }

  Future<void> updateProfile({required String name, required String shop, required String addr, String? photoUrl}) async {
    try {
      await _fb.updateProfile(uid!, {
        'name': name,
        'shop': shop,
        'address': addr,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    } catch (e) {
      _reportError('updateProfile', e);
      rethrow;
    }
  }
}
