import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int? id;
  final int? orderId;
  final String itemType;
  final int itemId;
  final int quantity;
  final double price;

  const OrderItem({
    this.id,
    this.orderId,
    required this.itemType,
    required this.itemId,
    this.quantity = 1,
    required this.price,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      orderId: json['orderId'] as int?,
      itemType: json['itemType'] as String,
      itemId: json['itemId'] as int,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'itemType': itemType,
      'itemId': itemId,
      'quantity': quantity,
      'price': price,
    };
  }

  @override
  List<Object?> get props => [id, orderId, itemType, itemId, quantity, price];
}

class Order extends Equatable {
  final int id;
  final int userId;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED
  final String? shippingAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    this.items = const [],
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      userId: json['userId'] as int,
      orderNumber: json['orderNumber'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      shippingAddress: json['shippingAddress'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        orderNumber,
        items,
        totalAmount,
        status,
        shippingAddress,
        createdAt,
        updatedAt,
      ];
}
