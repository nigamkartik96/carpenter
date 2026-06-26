import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'models.dart';

String _fmtTimestamp(dynamic ts) {
  if (ts is Timestamp) {
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
  return 'just now';
}

/// "Last seen" updates every few minutes while a carpenter has the app
/// open, so a date-only stamp would just show "today" all day -- include
/// the time, and only fall back to a full date once it's not today.
String _fmtLastSeen(dynamic ts) {
  if (ts is! Timestamp) return '-';
  final dt = ts.toDate();
  final now = DateTime.now();
  final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) return 'Today $time';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} $time';
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

double? _double(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Admin app state, backed by live Firestore listeners via
/// AdminFirebaseService. Screens read the cached lists below.
class AdminState extends ChangeNotifier {
  final AdminFirebaseService _fb = AdminFirebaseService.instance;

  bool loggedIn = false;
  String? loginError;
  String? lastError;
  bool busy = false;
  int screenIndex = 0;

  String? get adminEmail => _fb.auth.currentUser?.email;

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  void _reportError(String where, Object e) {
    lastError = '$where: $e';
    notifyListeners();
  }

  void goToScreen(int index) {
    screenIndex = index;
    notifyListeners();
  }

  int pointRuleAmount = 100;
  int pointRulePoints = 1;
  int minRedeemPoints = 500;
  int leadPointsQualified = 0;
  int leadPointsConverted = 0;

  final List<Carpenter> carpenters = [];
  final List<AdminOrder> orders = [];
  final List<AdminOffer> offers = [];
  final List<AdminGift> gifts = [];
  final List<Redemption> redemptions = [];
  final List<AdminLead> leads = [];
  final List<Broadcast> broadcasts = [];

  final List<StreamSubscription> _subs = [];

  Future<bool> tryResumeSession() async {
    if (!_fb.hasSession) return false;
    loggedIn = true;
    _startListening();
    notifyListeners();
    return true;
  }

  Future<void> login(String email, String password) async {
    busy = true;
    loginError = null;
    notifyListeners();
    try {
      // First admin login also bootstraps the account if it doesn't exist yet.
      await _fb.ensureAdminAccount(email, password);
      await _fb.login(email, password);
      loggedIn = true;
      _startListening();
    } catch (e) {
      loginError = 'Login failed. Check email/password.';
    }
    busy = false;
    notifyListeners();
  }

  Future<void> logout() async {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    await _fb.logout();
    loggedIn = false;
    carpenters.clear();
    orders.clear();
    offers.clear();
    gifts.clear();
    redemptions.clear();
    leads.clear();
    broadcasts.clear();
    notifyListeners();
  }

  void _startListening() {
    _subs.add(_fb.watchConfig().listen((snap) {
      try {
        final d = snap.data();
        if (d == null) return;
        pointRuleAmount = _int(d['pointRuleAmount'], 100);
        pointRulePoints = _int(d['pointRulePoints'], 1);
        minRedeemPoints = _int(d['minRedeemPoints'], 500);
        leadPointsQualified = _int(d['leadPointsQualified'], 0);
        leadPointsConverted = _int(d['leadPointsConverted'], 0);
        notifyListeners();
      } catch (e) {
        _reportError('config', e);
      }
    }, onError: (e) => _reportError('config', e)));

    _subs.add(_fb.watchCarpenters().listen((snap) {
      try {
        carpenters
          ..clear()
          ..addAll(snap.docs.map((doc) {
            final d = doc.data();
            final location = d['location'] as Map<String, dynamic>?;
            return Carpenter(
              id: doc.id,
              name: d['name'] ?? '',
              shop: d['shop'] ?? '',
              mobile: d['mobile'] ?? '',
              status: d['status'] ?? 'Pending',
              points: _int(d['points']),
              area: d['address'] ?? '-',
              tier: d['tier'] ?? 'Bronze',
              lastSeen: _fmtLastSeen(d['lastSeen']),
              lat: location != null ? _double(location['lat']) : null,
              lng: location != null ? _double(location['lng']) : null,
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('carpenters', e);
      }
    }, onError: (e) => _reportError('carpenters', e)));

    _subs.add(_fb.watchBroadcasts().listen((snap) {
      try {
        broadcasts
          ..clear()
          ..addAll(snap.docs.map((doc) {
            final d = doc.data();
            return Broadcast(
              title: d['title'] ?? '',
              body: d['body'] ?? '',
              tier: d['tier'] ?? 'All',
              date: _fmtTimestamp(d['createdAt']),
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('broadcasts', e);
      }
    }, onError: (e) => _reportError('broadcasts', e)));

    _subs.add(_fb.watchOrders().listen((snap) {
      try {
        orders
          ..clear()
          ..addAll(snap.docs.map((doc) {
            final d = doc.data();
            final rawItems = d['items'];
            return AdminOrder(
              id: doc.id,
              carpenterId: d['carpenterId'] ?? '',
              carpenterName: _carpenterName(d['carpenterId']),
              amount: _int(d['amount']),
              status: d['status'] ?? 'Submitted',
              products: [d['detail'] ?? ''],
              orderNumber: d['orderNumber'],
              type: d['type'] ?? 'Manual',
              detail: d['detail'] ?? '',
              imageUrl: d['imageUrl'],
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

    _subs.add(_fb.watchOffers().listen((snap) {
      try {
        offers
          ..clear()
          ..addAll(snap.docs.map((doc) {
            final d = doc.data();
            return AdminOffer(
              id: doc.id,
              title: d['title'] ?? '',
              description: d['description'] ?? '',
              category: d['category'] ?? 'Today',
              validTill: d['validTill'] ?? '',
              bannerUrl: d['bannerUrl'],
              pdfUrl: d['pdfUrl'],
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('offers', e);
      }
    }, onError: (e) => _reportError('offers', e)));

    _subs.add(_fb.watchGifts().listen((snap) {
      try {
        gifts
          ..clear()
          ..addAll(snap.docs.map((doc) {
            final d = doc.data();
            return AdminGift(id: doc.id, name: d['name'] ?? '', points: _int(d['points']), qty: _int(d['qty']), imageUrl: d['imageUrl']);
          }));
        notifyListeners();
      } catch (e) {
        _reportError('gifts', e);
      }
    }, onError: (e) => _reportError('gifts', e)));

    _subs.add(_fb.watchRedemptions().listen((snap) {
      try {
        redemptions
          ..clear()
          ..addAll(snap.docs.map((doc) {
            final d = doc.data();
            return Redemption(
              id: doc.id,
              carpenterId: d['carpenterId'] ?? '',
              carpenterName: _carpenterName(d['carpenterId']),
              giftName: d['giftName'] ?? '',
              points: _int(d['points']),
              status: d['status'] ?? 'Pending',
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('redemptions', e);
      }
    }, onError: (e) => _reportError('redemptions', e)));

    _subs.add(_fb.watchLeads().listen((snap) {
      try {
        leads
          ..clear()
          ..addAll(snap.docs.map((doc) {
            final d = doc.data();
            final geo = d['geo'] as Map<String, dynamic>?;
            return AdminLead(
              id: doc.id,
              customer: d['name'] ?? '',
              phone: d['phone'] ?? '',
              carpenter: _carpenterName(d['carpenterId']),
              carpenterId: d['carpenterId'] ?? '',
              status: d['status'] ?? 'New',
              notes: d['notes'] ?? '',
              location: d['location'] ?? '',
              lat: geo != null ? _double(geo['lat']) : null,
              lng: geo != null ? _double(geo['lng']) : null,
              pointsAwarded: _int(d['pointsAwarded']),
            );
          }));
        notifyListeners();
      } catch (e) {
        _reportError('leads', e);
      }
    }, onError: (e) => _reportError('leads', e)));
  }

  String _carpenterName(String? carpenterId) {
    if (carpenterId == null) return '-';
    final c = carpenters.where((c) => c.id == carpenterId);
    return c.isEmpty ? carpenterId : c.first.name;
  }

  Future<void> approve(Carpenter c) => _fb.approveCarpenter(c.id);
  Future<void> reject(Carpenter c) => _fb.rejectCarpenter(c.id);
  Future<void> setTier(Carpenter c, String tier) => _fb.setCarpenterTier(c.id, tier);

  Future<void> setOrderAmount(AdminOrder o, int amount) => _fb.setOrderAmount(o.id, amount);

  Future<void> setOrderItems(AdminOrder o, List<OrderItem> items) {
    final amount = items.fold<int>(0, (total, i) => total + i.total);
    return _fb.setOrderItems(
      o.id,
      items.map((i) => i.toMap()).toList(),
      amount,
      carpenterId: o.carpenterId,
      status: o.status,
      pointRuleAmount: pointRuleAmount,
      pointRulePoints: pointRulePoints,
    );
  }

  Future<void> setOrderInvoice(AdminOrder o, String invoiceUrl) => _fb.setOrderInvoice(o.id, invoiceUrl);

  Future<void> setOrderStatus(AdminOrder o, String status) {
    return _fb.setOrderStatus(
      orderId: o.id,
      carpenterId: o.carpenterId,
      status: status,
      pointRuleAmount: pointRuleAmount,
      pointRulePoints: pointRulePoints,
      orderAmount: o.amount,
    );
  }

  Future<void> setRedemptionStatus(Redemption r, String status) {
    return _fb.setRedemptionStatus(id: r.id, carpenterId: r.carpenterId, status: status);
  }

  Future<void> setLeadStatus(AdminLead l, String status) => _fb.setLeadStatus(
        id: l.id,
        carpenterId: l.carpenterId,
        status: status,
        qualifiedPoints: leadPointsQualified,
        convertedPoints: leadPointsConverted,
      );

  Future<void> setLeadPointsRule({required int qualifiedPoints, required int convertedPoints}) async {
    leadPointsQualified = qualifiedPoints;
    leadPointsConverted = convertedPoints;
    notifyListeners();
    await _fb.saveLeadPointsRule(qualifiedPoints: qualifiedPoints, convertedPoints: convertedPoints);
  }

  Future<void> addOffer(String title, String category, String validTill, {String description = '', String? bannerUrl, String? pdfUrl}) {
    return _fb.addOffer(title: title, category: category, validTill: validTill, description: description, bannerUrl: bannerUrl, pdfUrl: pdfUrl);
  }

  Future<void> withdrawOffer(AdminOffer o) => _fb.withdrawOffer(o.id);

  Future<void> addGift(String name, int points, int qty, {String? imageUrl}) {
    return _fb.addGift(name: name, points: points, qty: qty, imageUrl: imageUrl);
  }

  Future<void> setPointRule(int amount, int points, int minRedeem) async {
    pointRuleAmount = amount;
    pointRulePoints = points;
    minRedeemPoints = minRedeem;
    notifyListeners();
    await _fb.saveConfig(pointRuleAmount: amount, pointRulePoints: points, minRedeemPoints: minRedeem);
  }

  Future<void> broadcastNotification(String title, String body, String tier) async {
    await _fb.broadcastNotification(title, body.isEmpty ? title : body, tier);
  }
}
