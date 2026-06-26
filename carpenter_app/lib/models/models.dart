class OrderItem {
  OrderItem({required this.name, required this.qty, required this.unitCost});
  final String name;
  final int qty;
  final int unitCost;
  int get total => qty * unitCost;

  static OrderItem fromMap(Map<String, dynamic> m) => OrderItem(
        name: m['name'] ?? '',
        qty: (m['qty'] is int) ? m['qty'] : int.tryParse('${m['qty']}') ?? 0,
        unitCost: (m['unitCost'] is int) ? m['unitCost'] : int.tryParse('${m['unitCost']}') ?? 0,
      );
}

class CarpenterOrder {
  CarpenterOrder({
    required this.id,
    required this.type,
    required this.detail,
    required this.status,
    required this.date,
    this.points = 0,
    this.imageUrl,
    this.items = const [],
    this.invoiceUrl,
    this.audioUrl,
    String? orderNumber,
  }) : orderNumber = orderNumber ?? id;

  final String id;
  final String type; // Manual, Photo, Voice
  final String detail;
  String status; // Submitted, Processing, Fulfilled, Delivered, Cancelled
  final String date;
  int points;
  final String? imageUrl;
  final String orderNumber; // human-readable, e.g. OD-0001
  final List<OrderItem> items;
  final String? invoiceUrl;
  final String? audioUrl; // voice-note recording, for 'Voice' type orders
}

class Offer {
  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.category, // Today, Weekly, Other
    required this.validTill,
    this.bannerUrl,
    this.pdfUrl,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String validTill;
  final String? bannerUrl;
  final String? pdfUrl;
}

class Gift {
  Gift({
    required this.id,
    required this.name,
    required this.points,
    required this.qty,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int points;
  int qty;
  final String? imageUrl;
}

class GiftRedemption {
  GiftRedemption({
    required this.id,
    required this.giftName,
    required this.points,
    required this.date,
    this.status = 'Pending',
  });

  final String id;
  final String giftName;
  final int points;
  final String date;
  String status; // Ordered, In store, Delivered
}

class Lead {
  Lead({
    required this.name,
    required this.phone,
    this.location = '',
    this.notes = '',
    this.status = 'New',
    this.lat,
    this.lng,
    this.pointsAwarded = 0,
  });

  final String name;
  final String phone;
  final String location;
  final String notes;
  String status; // New, Contacted, Qualified, Converted, Closed
  final double? lat;
  final double? lng;
  int pointsAwarded;
}

class LeaderboardEntry {
  LeaderboardEntry(this.initials, this.name, this.points, {this.photoUrl});
  final String initials;
  final String name;
  final int points;
  final String? photoUrl;
}

class PointsLedgerEntry {
  PointsLedgerEntry(this.desc, this.points, this.date);
  final String desc;
  final int points;
  final String date;
}

class AppNotification {
  AppNotification(this.id, this.title, this.body, this.time, {this.read = false, this.type, this.refId});
  final String id;
  final String title;
  final String body;
  final String time;
  bool read;
  final String? type; // e.g. 'offer'
  final String? refId; // e.g. offer id, for deep-linking on tap
}
