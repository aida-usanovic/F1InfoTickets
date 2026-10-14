import '../core/json.dart';

class Ticket {
  final int ticketID;
  final int userID;
  final String? username;
  final String? customerName;
  final int raceID;
  final String? raceName;
  final DateTime raceDate;
  final String? circuitName;
  final String? ticketType;
  final double price;
  final DateTime purchaseDate;
  final String qrCode;
  final int paymentID;
  final String? paymentMethod;
  final String? paymentStatus;
  final String status;

  Ticket({
    required this.ticketID,
    required this.userID,
    this.username,
    this.customerName,
    required this.raceID,
    this.raceName,
    required this.raceDate,
    this.circuitName,
    this.ticketType,
    required this.price,
    required this.purchaseDate,
    required this.qrCode,
    required this.paymentID,
    this.paymentMethod,
    this.paymentStatus,
    required this.status,
  });

  /// Status text shown to users.
  String get statusLabel => switch (status) {
    'Active' => 'Valid',
    'Used' => 'Used',
    'Refunded' => 'Refunded',
    _ => status,
  };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    ticketID: json['ticketID'],
    userID: json['userID'],
    username: json['username'],
    customerName: json['customerName'],
    raceID: json['raceID'],
    raceName: json['raceName'],
    raceDate: parseDateTime(json['raceDate']),
    circuitName: json['circuitName'],
    ticketType: json['ticketType'],
    price: toDouble(json['price']),
    purchaseDate: parseDateTime(json['purchaseDate']),
    qrCode: json['qrCode'],
    paymentID: json['paymentID'],
    paymentMethod: json['paymentMethod'],
    paymentStatus: json['paymentStatus'],
    status: json['status'],
  );
}

class CartItem {
  final int cartItemID;
  final int raceTicketCategoryID;
  final int raceID;
  final String? raceName;
  final DateTime raceDate;
  final String? circuitName;
  final String? ticketType;
  final double unitPrice;
  final int quantity;
  final int available;
  final double subtotal;

  CartItem({
    required this.cartItemID,
    required this.raceTicketCategoryID,
    required this.raceID,
    this.raceName,
    required this.raceDate,
    this.circuitName,
    this.ticketType,
    required this.unitPrice,
    required this.quantity,
    required this.available,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    cartItemID: json['cartItemID'],
    raceTicketCategoryID: json['raceTicketCategoryID'],
    raceID: json['raceID'],
    raceName: json['raceName'],
    raceDate: parseDateTime(json['raceDate']),
    circuitName: json['circuitName'],
    ticketType: json['ticketType'],
    unitPrice: toDouble(json['unitPrice']),
    quantity: json['quantity'],
    available: json['available'],
    subtotal: toDouble(json['subtotal']),
  );
}

class Cart {
  final List<CartItem> items;
  final int totalQuantity;
  final double total;

  Cart({required this.items, required this.totalQuantity, required this.total});

  static final empty = Cart(items: const [], totalQuantity: 0, total: 0);

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    items: (json['items'] as List).map((e) => CartItem.fromJson(e)).toList(),
    totalQuantity: json['totalQuantity'],
    total: toDouble(json['total']),
  );
}

class PaymentResponse {
  final int? paymentID;
  final String providerOrderId;
  final String approvalUrl;
  final String status;

  PaymentResponse({this.paymentID, required this.providerOrderId, required this.approvalUrl, required this.status});

  factory PaymentResponse.fromJson(Map<String, dynamic> json) => PaymentResponse(
    paymentID: json['paymentID'],
    providerOrderId: json['providerOrderId'] ?? '',
    approvalUrl: json['approvalUrl'] ?? '',
    status: json['status'] ?? '',
  );
}
