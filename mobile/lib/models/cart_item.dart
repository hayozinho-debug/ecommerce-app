class CartItem {
  final int id;
  final int productId;
  final String productTitle;
  final double productPrice;
  final int? variantId;
  final List<String> images;
  final String? selectedColor;
  final String? selectedSize;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    this.variantId,
    required this.images,
    this.selectedColor,
    this.selectedSize,
    required this.quantity,
  });

  double get subtotal => productPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      productTitle: json['productTitle'] ?? '',
      productPrice: (json['productPrice'] ?? 0).toDouble(),
      variantId: json['variantId'],
      images: List<String>.from(json['images'] ?? []),
      selectedColor: json['selectedColor'],
      selectedSize: json['selectedSize'],
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'productPrice': productPrice,
      'variantId': variantId,
      'images': images,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'quantity': quantity,
    };
  }
}
