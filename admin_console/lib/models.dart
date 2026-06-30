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
  });

  final String id;
  final String name;
  final String shop;
  final String mobile;
  String status; // Pending, Approved, Rejected
  int points;
  String lastSeen;
  String area;
  String tier; // Bronze, Silver, Gold, Platinum -- admin-assigned, used to target notifications
  // Reported by the carpenter app while it's open (see AppState.reportLocationOnce
  // on that side) -- null until the carpenter has opened the app at least
  // once after accepting location sharing.
  final double? lat;
  final double? lng;
  final String? photoUrl;
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
  String status; // Submitted, Processing, Fulfilled, Delivered
  final String orderNumber; // human-readable, e.g. OD-0001
  final List<String> products;
  final List<OrderItem> items;
  final String? invoiceUrl;
  final String detail;
  final String? imageUrl;
  final String? audioUrl; // voice-note recording, for 'Voice' type orders
  final String type; // Manual, Photo, Voice
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
