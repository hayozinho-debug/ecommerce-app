class Order {
  final String id;
  final String userId;
  final double total;
  final String status;
  final List<OrderItem> items;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => OrderItem.fromJson(i))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'total': total,
      'status': status,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toString(),
    };
  }
}

class OrderItem {
  final int id;
  final int productId;
  final int? variantId;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      variantId: json['variantId'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'price': price,
    };
  }
}
