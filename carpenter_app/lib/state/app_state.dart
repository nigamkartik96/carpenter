import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/background_location.dart';
import '../services/biometric_service.dart';
import '../services/firebase_service.dart';
import '../services/push_service.dart';

String initialsOf(String name) {
  final n = name.trim();
  if (n.isEmpty) return '?';
  return n.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
}

/// Mobile numbers get typed with spaces, dashes and sometimes a +91
/// prefix. Reducing to the last 10 digits means the same number always
/// maps to the same account whichever way the carpenter enters it.
String normalizeMobile(String mobile) {
  final digits = mobile.replaceAll(RegExp(r'\D'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

/// Firebase Auth has no password-based mobile sign-in, so an account
/// registered without an email address gets a synthetic one derived from
/// the carpenter's mobile number, used purely as the login ID. The
/// `.invalid` TLD is reserved by RFC 2606 and can never receive mail,
/// which is exactly the point: nothing is ever sent here, the carpenter
/// is never shown it, and their profile's `email` field stays empty.
/// Two consequences worth knowing: two accounts can't share a mobile
/// number (Firebase rejects the duplicate), and these accounts have no
/// email to send a password reset to.
String mobileAuthEmail(String mobile) => '${normalizeMobile(mobile)}@carpenterhub.invalid';

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
class AppState extends ChangeNotifier with WidgetsBindingObserver {
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

  bool pinSet = false;
  String? pinHash;
  bool resetPin = false;
  bool resetPassword = false;

  String? lastUserName;
  String? lastUserIdentifier;
  bool lastUserPinSet = false;
  String? lastUserPinHash;

  int pointRuleAmount = 100;
  int pointRulePoints = 1;
  int minRedeemPoints = 500;

  String? lastError;

  final List<LeaderboardEntry> leaderboard = [];
  final List<Offer> offers = [];
  final List<CarpenterOrder> orders = [];
  Map<String, CarpenterOrder> _orderMap = {};
  Map<String, Offer> _offerMap = {};
  CarpenterOrder? orderById(String id) => _orderMap[id];
  Offer? offerById(String id) => _offerMap[id];
  final List<Gift> gifts = [];
  final List<GiftRedemption> redemptions = [];
  final List<PointsLedgerEntry> ledger = [];
  final List<Lead> leads = [];
  final List<AppNotification> notifications = [];
  int get unreadCount => notifications.where((n) => !n.read).length;
  int get totalPoints => lifetimePoints - redeemedPoints;
  static final _partyEntryPattern = RegExp(r'^Payment received from ');
  List<PointsLedgerEntry> get visibleLedger => ledger.where((l) => !_partyEntryPattern.hasMatch(l.desc)).toList();

  String tr(String key) => locale.tr(key);
  String trf(String key, Object n) => locale.trf(key, n);

  /// Translates points-ledger/notification text that was written verbatim
  /// as English by whichever backend generated the event -- see
  /// [translateDynamicText] for why this can't just be another [tr] key.
  String trDyn(String text) => translateDynamicText(locale, text);

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

  Future<void> loadLastUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      lastUserName = prefs.getString('lastUserName');
      lastUserIdentifier = prefs.getString('lastUserIdentifier');
      lastUserPinSet = prefs.getBool('lastUserPinSet') ?? false;
      lastUserPinHash = prefs.getString('lastUserPinHash');
    } catch (_) {}
  }

  Future<void> _saveLastUser(String identifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastUserName', carpenterName);
      await prefs.setString('lastUserIdentifier', identifier);
      await prefs.setBool('lastUserPinSet', pinSet);
      if (pinHash != null) {
        await prefs.setString('lastUserPinHash', pinHash!);
      } else {
        await prefs.remove('lastUserPinHash');
      }
      lastUserName = carpenterName;
      lastUserIdentifier = identifier;
      lastUserPinSet = pinSet;
      lastUserPinHash = pinHash;
    } catch (_) {}
  }

  Future<void> _refreshCachedLastUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('lastUserIdentifier') == null) return;
      await prefs.setString('lastUserName', carpenterName);
      await prefs.setBool('lastUserPinSet', pinSet);
      if (pinHash != null) {
        await prefs.setString('lastUserPinHash', pinHash!);
      }
    } catch (_) {}
  }

  Future<void> clearLastUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastUserName');
      await prefs.remove('lastUserIdentifier');
      await prefs.remove('lastUserPinSet');
      await prefs.remove('lastUserPinHash');
    } catch (_) {}
    lastUserName = null;
    lastUserIdentifier = null;
    lastUserPinSet = false;
    lastUserPinHash = null;
  }

  Future<String> loginWithPin(String pin) async {
    final enteredHash = sha256.convert(utf8.encode(pin)).toString();
    if (lastUserPinHash == null || enteredHash != lastUserPinHash) {
      return 'Incorrect PIN';
    }
    final creds = await BiometricService.instance.loadCredentials();
    if (creds == null) {
      return 'Saved credentials not found. Please use password.';
    }
    return login(creds.$1, creds.$2);
  }

  Future<bool> verifyPassword(String password) async {
    final user = _fb.currentUser;
    if (user == null || user.email == null) return false;
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _reportAnalytics() async {
    if (uid == null) return;
    try {
      final info = await PackageInfo.fromPlatform();
      await _fb.reportAnalytics(
        uid!,
        appVersion: info.version,
        buildNumber: int.tryParse(info.buildNumber) ?? 0,
      );
    } catch (e) {
      debugPrint('analytics: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (uid == null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _fb.setOnlineStatus(uid!, false).catchError((_) {});
    } else if (state == AppLifecycleState.resumed) {
      _fb.setOnlineStatus(uid!, true).catchError((_) {});
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

  Future<bool> tryResumeSession() async {
    final user = _fb.currentUser;
    if (user == null) return false;
    final approved = await _refreshStatusOnce();
    if (approved) {
      _startListening();
      startLocationReporting();
      WidgetsBinding.instance.addObserver(this);
      _reportAnalytics();
      _refreshCachedLastUser();
    }
    return true;
  }

  /// [email] is optional -- carpenters who don't have one register with
  /// just their mobile number, which then doubles as their login ID (see
  /// [mobileAuthEmail]). A supplied email is used for auth as before.
  Future<String> register({
    required String name,
    required String mobileNum,
    required String password,
    required String shop,
    required String addr,
    String email = '',
    String? photoUrl,
    String? pin,
  }) async {
    final realEmail = email.trim();
    try {
      await _fb.registerCarpenter(
        authEmail: realEmail.isEmpty ? mobileAuthEmail(mobileNum) : realEmail,
        email: realEmail,
        password: password,
        name: name,
        mobile: mobileNum,
        shop: shop,
        address: addr,
        photoUrl: photoUrl,
        pinHash: pin != null ? sha256.convert(utf8.encode(pin)).toString() : null,
      );
      return 'ok';
    } on FirebaseAuthException catch (e) {
      // Without an email of their own, "that address is taken" reads as
      // nonsense -- what it actually means is this mobile number already
      // has an account.
      if (e.code == 'email-already-in-use' && realEmail.isEmpty) {
        return 'An account already exists for this mobile number';
      }
      return e.message ?? 'Registration failed';
    }
  }

  /// [identifier] is either an email address or a mobile number --
  /// carpenters registered without an email sign in with the latter.
  Future<String> login(String identifier, String password) async {
    final id = identifier.trim();
    final email = id.contains('@') ? id : mobileAuthEmail(id);
    try {
      final cred = await _fb.login(email, password);
      uid = cred.user!.uid;
      await _refreshStatusOnce();
      if (isApproved) {
        _startListening();
        startLocationReporting();
        WidgetsBinding.instance.addObserver(this);
        _reportAnalytics();
      }
      BiometricService.instance.saveCredentials(id, password).catchError((_) {});
      _saveLastUser(id);
      return 'ok';
    } on FirebaseAuthException catch (e) {
      // Firebase's own wording talks about email addresses, which is
      // confusing for someone who signed up with only a mobile number.
      if (e.code == 'user-not-found') {
        return 'No account found for that mobile number or email';
      }
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        return 'Wrong mobile number, email or password';
      }
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'Login failed. Check your internet connection.';
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
    pinSet = d['pinSet'] == true;
    pinHash = d['pinHash'] as String?;
    resetPin = d['resetPin'] == true;
    resetPassword = d['resetPassword'] == true;
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
    if (approved && _subs.isEmpty) _startListening();
    return approved;
  }

  Future<void> logout() async {
    if (uid != null) {
      await _fb.setOnlineStatus(uid!, false).catchError((_) {});
      await PushService.instance.unregisterToken(uid!);
    }
    WidgetsBinding.instance.removeObserver(this);
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('location: device location services are off');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('location: permission $permission');
        return;
      }
      final pos = await currentPosition();
      if (pos == null) {
        debugPrint('location: no fix available');
        return;
      }
      if (uid != null) await _fb.updateLocation(uid!, pos.latitude, pos.longitude);
    } catch (e) {
      // Best-effort -- a flaky GPS fix shouldn't surface as an app-wide
      // error banner. Logged rather than swallowed: this used to fail
      // completely silently, which is why nobody noticed the admin map
      // was frozen on whatever position was captured at sign-up.
      debugPrint('location: report failed: $e');
    }
  }

  /// Waiting on a fresh GPS fix indoors can hang indefinitely, which is
  /// what an un-timed getCurrentPosition() does -- the periodic timer
  /// then just stacks up calls that never complete. Cap the wait and
  /// fall back to the last fix Android already has, which for a
  /// "where was this carpenter recently" map is fine.
  static Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      debugPrint('location: live fix failed ($e), trying last known');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// True once the carpenter has granted "Allow all the time".
  ///
  /// Android 10+ only ever grants "while using the app" from the normal
  /// permission prompt, and that is NOT enough for the hourly background
  /// job -- it silently gets no fix once the app leaves the foreground.
  /// On Android 11+ the always-on option cannot be requested from a
  /// dialog at all; the carpenter has to pick it in system settings,
  /// which is what [openLocationSettings] is for.
  Future<bool> hasBackgroundLocationPermission() async {
    try {
      return await Geolocator.checkPermission() == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// Asks for foreground location, then tries to upgrade to always-on.
  /// Returns true if always-on was granted without needing a trip to
  /// settings (Android 9 and below, or if the carpenter had already
  /// allowed it).
  Future<bool> requestLocationPermissions() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse) {
        // Harmless where the OS won't offer it; grants directly on older
        // Android versions.
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always;
    } catch (e) {
      debugPrint('location: permission request failed: $e');
      return false;
    }
  }

  Future<void> openLocationSettings() => Geolocator.openAppSettings();

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

  void _startListening() {
    final id = uid!;

    // Only approved carpenters reach here, which is also when push
    // becomes useful -- there's nothing to notify a pending account
    // about. Fire-and-forget: a failed token save must not stop the
    // Firestore listeners below from starting.
    PushService.instance.registerToken(id);

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
        pinSet = d['pinSet'] == true;
        pinHash = d['pinHash'] as String?;
        resetPin = d['resetPin'] == true;
        resetPassword = d['resetPassword'] == true;
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
        _offerMap = {for (final o in offers) o.id: o};
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
        _orderMap = {for (final o in orders) o.id: o};
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
        final docs = snap.docs;
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

  bool get needsForceReset => resetPin || resetPassword;

  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _fb.setPin(uid!, hash);
  }

  Future<void> resetPasswordTo(String newPassword) async {
    await _fb.auth.currentUser!.updatePassword(newPassword);
    await _fb.clearResetPassword(uid!);
    BiometricService.instance.saveCredentials(mobile, newPassword).catchError((_) {});
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

  Stream<List<OrderComment>> watchOrderComments(String orderId) =>
      _fb.watchOrderComments(orderId).map((snap) => snap.docs.map((d) {
            final m = d.data();
            return OrderComment(
              text: '${m['text'] ?? ''}',
              authorRole: '${m['authorRole'] ?? ''}',
              authorName: '${m['authorName'] ?? ''}',
              createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : null,
            );
          }).toList());

  Future<void> addOrderComment(String orderId, String text) async {
    try {
      await _fb.addOrderComment(orderId, authorName: carpenterName, text: text);
    } catch (e) {
      _reportError('addOrderComment', e);
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

  /// At least one of [text], [audioUrl] or [imageUrl] is expected --
  /// the screen enforces that before calling.
  Future<void> submitFeedback({String text = '', String? audioUrl, String? imageUrl}) async {
    try {
      await _fb.addFeedback(uid!, {
        'text': text,
        'carpenterName': carpenterName,
        'mobile': mobile,
        if (audioUrl != null) 'audioUrl': audioUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
    } catch (e) {
      _reportError('submitFeedback', e);
      rethrow;
    }
  }

  Future<void> savePayout(Map<String, String> data) async {
    await _fb.savePayoutDetails(uid!, data);
  }

  Future<void> markNotificationsRead() async {
    if (notifications.isEmpty) return;
    final ids = notifications.map((n) => n.id).toList();
    notifications.clear();
    notifyListeners();
    try {
      await _fb.deleteNotifications(ids);
    } catch (e) {
      _reportError('deleteNotifications', e);
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
