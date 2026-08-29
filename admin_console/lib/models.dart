const carpenterTiers = ['Bronze', 'Silver', 'Gold', 'Platinum'];

class Carpenter {
  Carpenter({
    required this.id,
    required this.name,
    required this.shop,
    required this.mobile,
    this.status = 'Pending',
    this.points = 0,
    this.lastSeen = '-',
    this.area = '-',
    this.tier = 'Bronze',
    this.lat,
    this.lng,
    this.photoUrl,
    this.upiId = '',
    this.bankName = '',
    this.qrUrl,
    this.lastLogin,
    this.appVersion,
    this.appBuildNumber,
    this.isOnline = false,
    this.loginCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String shop;
  final String mobile;
  String status;
  int points;
  String lastSeen;
  String area;
  String tier;
  final double? lat;
  final double? lng;
  final String? photoUrl;
  final String upiId;
  final String bankName;
  final String? qrUrl;

  final DateTime? lastLogin;
  final String? appVersion;
  final int? appBuildNumber;
  final bool isOnline;
  final int loginCount;
  final DateTime? createdAt;

  bool get hasPaymentInfo => upiId.isNotEmpty || bankName.isNotEmpty || qrUrl != null;
}

class Broadcast {
  Broadcast({required this.title, required this.body, required this.tier, required this.date});
  final String title;
  final String body;
  final String tier; // 'All' or one of carpenterTiers
  final String date;
}

class OrderItem {
  OrderItem({required this.name, required this.qty, required this.unitCost});
  final String name;
  final int qty;
  final int unitCost;
  int get total => qty * unitCost;

  Map<String, dynamic> toMap() => {'name': name, 'qty': qty, 'unitCost': unitCost};

  static OrderItem fromMap(Map<String, dynamic> m) => OrderItem(
        name: m['name'] ?? '',
        qty: (m['qty'] is int) ? m['qty'] : int.tryParse('${m['qty']}') ?? 0,
        unitCost: (m['unitCost'] is int) ? m['unitCost'] : int.tryParse('${m['unitCost']}') ?? 0,
      );
}

class AdminOrder {
  AdminOrder({
    required this.id,
    required this.carpenterId,
    required this.carpenterName,
    required this.amount,
    this.points = 0,
    this.partyName = '',
    this.partyPhone = '',
    this.status = 'Pending',
    this.products = const [],
    this.items = const [],
    this.invoiceUrl,
    this.detail = '',
    this.imageUrl,
    this.audioUrl,
    this.type = 'Manual',
    this.createdAt,
    String? orderNumber,
  }) : orderNumber = orderNumber ?? id;

  final String id;
  final String carpenterId;
  final String carpenterName;
  final int amount;
  // Points the admin typed in by hand on the order detail screen. During
  // the MVP these are worked out off-system, so the amount -> points
  // conversion rule deliberately does not apply to regular orders.
  final int points;
  final String partyName;
  final String partyPhone;
  String status; // Submitted, Processing, Fulfilled, Delivered
  final String orderNumber; // human-readable, e.g. OD-0001
  final List<String> products;
  // What the carpenter asked for in the app -- read-only here; the admin
  // no longer edits or prices these line by line.
  final List<OrderItem> items;
  final String? invoiceUrl;
  final String detail;
  final String? imageUrl;
  final String? audioUrl; // voice-note recording, for 'Voice' type orders
  final String type; // Manual, Photo, Voice
  final DateTime? createdAt;
}

/// One message in an order's admin <-> carpenter comment thread
/// (`orders/{id}/comments`). Same shape on the carpenter-app side.
class OrderComment {
  OrderComment({required this.text, required this.authorRole, this.authorName = '', this.createdAt});
  final String text;
  final String authorRole; // 'admin' | 'carpenter'
  final String authorName;
  final DateTime? createdAt; // null while the server timestamp is pending

  bool get fromAdmin => authorRole == 'admin';
}

/// A problem a carpenter reported from the app. Any combination of typed
/// text, a voice note and a photo -- carpenters who don't write
/// comfortably send only the latter two, so none of them is required.
class FeedbackEntry {
  FeedbackEntry({
    required this.id,
    required this.carpenterId,
    required this.carpenterName,
    this.mobile = '',
    this.text = '',
    this.audioUrl,
    this.imageUrl,
    this.status = 'New',
    this.createdAt,
  });
  final String id;
  final String carpenterId;
  final String carpenterName;
  final String mobile;
  final String text;
  final String? audioUrl;
  final String? imageUrl;
  String status; // New, Resolved
  final DateTime? createdAt;
}

class AdminOffer {
  AdminOffer({
    required this.id,
    required this.title,
    required this.category,
    required this.validTill,
    this.description = '',
    this.bannerUrl,
    this.pdfUrl,
    this.targetCarpenterIds,
    this.status = 'Live',
  });
  final String id;
  final String title;
  final String description;
  final String category; // Today, Weekly, Other
  final String validTill;
  final String? bannerUrl;
  final String? pdfUrl;
  // null or empty = visible to every approved carpenter; otherwise only
  // to carpenters whose id is in this list.
  final List<String>? targetCarpenterIds;
  final String status; // Live, Withdrawn
}

class AdminGift {
  AdminGift({required this.id, required this.name, required this.points, required this.qty, this.imageUrl, this.description = '', this.status = 'Live'});
  final String id;
  final String name;
  final int points;
  int qty;
  final String? imageUrl;
  final String description;
  final String status; // Live, Withdrawn
}

class Redemption {
  Redemption({
    required this.id,
    required this.carpenterId,
    required this.carpenterName,
    required this.giftName,
    required this.points,
    this.status = 'Pending',
  });
  final String id;
  final String carpenterId;
  final String carpenterName;
  final String giftName;
  final int points;
  String status; // Pending, Approved, On store, Dispatched, Delivered
}

/// A single payment the party made against a [PartyOrder]. Each one credits
/// the carpenter points at the time it's recorded, so [points] is captured
/// per-payment rather than recomputed from the total.
class PartyPayment {
  PartyPayment({required this.amount, required this.points, this.at});
  final int amount;
  final int points;
  // When the collection was recorded. Payments live in an array on the order
  // doc, and FieldValue.serverTimestamp() can't be used inside an array
  // element, so this is stamped client-side at record time. Null on rows
  // written before dates were tracked. Kept as a DateTime here (this file
  // stays Firestore-free); state.dart converts the Timestamp on the way in,
  // and the SDK accepts a DateTime on the way out.
  final DateTime? at;

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'points': points,
        if (at != null) 'at': at,
      };

  static PartyPayment fromMap(Map<String, dynamic> m) => PartyPayment(
        amount: (m['amount'] is int) ? m['amount'] : int.tryParse('${m['amount']}') ?? 0,
        points: (m['points'] is int) ? m['points'] : int.tryParse('${m['points']}') ?? 0,
        at: m['at'] is DateTime ? m['at'] as DateTime : null,
      );
}

/// An order the order-creator role logs on a carpenter's behalf, taken from
/// a party. Lives in its own `partyOrders` collection that the carpenter app
/// never reads -- only the points from each recorded payment reach the
/// carpenter (via pointsLedger + a notification). Distinct from [AdminOrder],
/// which is a real order the carpenter placed in the mobile app.
class PartyOrder {
  PartyOrder({
    required this.id,
    required this.carpenterId,
    required this.carpenterName,
    required this.party,
    required this.amount,
    this.rewardAmount = 0,
    this.status = 'pending',
    this.approvedAmount = 0,
    this.rewardPercent = 10,
    this.fileUrl,
    this.fileType,
    this.payments = const [],
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String carpenterId;
  final String carpenterName; // denormalized at create time so the list needs no join
  final String party;
  final int amount; // amount the creator entered
  // The slice of [amount] that actually earns points -- never more than the
  // amount itself. Set by the creator at create time. Legacy docs written
  // before rewards existed default to the full amount, which reproduces the
  // old "reward % of everything collected" behaviour.
  final int rewardAmount;
  String status; // pending, approved, completed
  int approvedAmount; // set by the admin on approval
  int rewardPercent; // % of the reward amount credited as points (0-100)
  final String? fileUrl;
  final String? fileType; // 'image' or 'pdf'
  final List<PartyPayment> payments;
  final String? createdBy; // uid of the order-creator account
  final DateTime? createdAt;

  int get paid => payments.fold(0, (s, p) => s + p.amount);
  int get pointsAwarded => payments.fold(0, (s, p) => s + p.points);
  int get remaining => (approvedAmount - paid).clamp(0, approvedAmount);
  bool get editable => status == 'pending'; // creator can edit only before approval

  /// What payments are collected against -- the admin's approved figure once
  /// set, otherwise the amount the creator entered.
  int get collectableAmount => approvedAmount > 0 ? approvedAmount : amount;

  /// Reward base, guarded against ever exceeding what's being collected (an
  /// admin can approve a smaller figure than the creator entered, which would
  /// otherwise push the ratio above 1 and inflate points).
  int get effectiveRewardAmount => rewardAmount <= 0
      ? collectableAmount
      : (rewardAmount > collectableAmount ? collectableAmount : rewardAmount);

  /// Points this order is worth in total, once every rupee is collected:
  /// reward % of the reward amount.
  int get maxPoints => (effectiveRewardAmount * rewardPercent) ~/ 100;

  /// Points a single recorded payment earns, scored on its own: the payment's
  /// share of the reward amount, times reward %.
  ///
  /// Each payment stands alone rather than being derived from the running
  /// total, so every row in the payment history carries its own calculation.
  /// The trade-off is truncation -- a payment worth less than a whole point
  /// earns 0, and those fractions don't carry over to later payments, so the
  /// sum across many small instalments can fall short of [maxPoints].
  int pointsForPayment(int payment) {
    final base = collectableAmount;
    if (base <= 0) return 0;
    final capped = payment > base ? base : payment;
    return (capped * effectiveRewardAmount * rewardPercent) ~/ (base * 100);
  }

  /// The arithmetic behind [pointsForPayment], spelled out for the payment
  /// history so the figure can be checked by eye.
  String pointsWorking(int payment) {
    final base = collectableAmount;
    if (base <= 0) return '';
    final rewardShare = (payment * effectiveRewardAmount) / base;
    final share = rewardShare == rewardShare.roundToDouble() ? rewardShare.round().toString() : rewardShare.toStringAsFixed(2);
    return '₹$payment x ₹$effectiveRewardAmount/₹$base = ₹$share reward x $rewardPercent% = ${pointsForPayment(payment)} pts';
  }
}

class AdminLead {
  AdminLead({
    required this.id,
    required this.customer,
    required this.phone,
    required this.carpenter,
    this.carpenterId = '',
    this.status = 'New',
    this.notes = '',
    this.location = '',
    this.lat,
    this.lng,
    this.pointsAwarded = 0,
  });
  final String id;
  final String customer;
  final String phone;
  final String carpenter;
  final String carpenterId;
  String status; // New, Contacted, Qualified, Converted, Closed
  final String notes;
  final String location;
  final double? lat;
  final double? lng;
  int pointsAwarded;
}
