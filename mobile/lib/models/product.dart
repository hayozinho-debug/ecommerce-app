class ProductImage {
  final String url;
  final String? altText;

  ProductImage({
    required this.url,
    this.altText,
  });

  factory ProductImage.fromJson(dynamic json) {
    // Se json é uma String (URL direta), criar objeto com altText null
    if (json is String) {
      return ProductImage(url: json, altText: null);
    }
    // Se json é um Map, extrair url e altText
    if (json is Map<String, dynamic>) {
      return ProductImage(
        url: json['url'] ?? '',
        altText: json['altText'],
      );
    }
    // Fallback
    return ProductImage(url: '', altText: null);
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'altText': altText,
    };
  }
}

class Product {
  final int id;
  final String title;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final List<ProductImage> images;
  final int? categoryId;
  final List<ProductVariant>? variants;
  final String? bulletPoints;
  final String? metafield01Foto;
  final String? metafield02Foto;
  final String? metafield03Foto;
  final String? tabelaMedida;

  Product({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.compareAtPrice,
    required this.images,
    this.categoryId,
    this.variants,
    this.bulletPoints,
    this.metafield01Foto,
    this.metafield02Foto,
    this.metafield03Foto,
    this.tabelaMedida,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      compareAtPrice: json['compareAtPrice']?.toDouble(),
      images: (json['images'] as List?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
      categoryId: json['categoryId'],
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((v) => ProductVariant.fromJson(v))
              .toList()
          : null,
      bulletPoints: json['bulletPoints'],
      metafield01Foto: json['metafield01Foto'],
      metafield02Foto: json['metafield02Foto'],
      metafield03Foto: json['metafield03Foto'],
      tabelaMedida: json['tabelaMedida'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'images': images.map((img) => img.toJson()).toList(),
      'categoryId': categoryId,
      'bulletPoints': bulletPoints,
      'metafield01Foto': metafield01Foto,
      'metafield02Foto': metafield02Foto,
      'metafield03Foto': metafield03Foto,
      'tabelaMedida': tabelaMedida,
    };
  }

  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    double? compareAtPrice,
    List<ProductImage>? images,
    int? categoryId,
    List<ProductVariant>? variants,
    String? bulletPoints,
    String? metafield01Foto,
    String? metafield02Foto,
    String? metafield03Foto,
    String? tabelaMedida,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      variants: variants ?? this.variants,
      bulletPoints: bulletPoints ?? this.bulletPoints,
      metafield01Foto: metafield01Foto ?? this.metafield01Foto,
      metafield02Foto: metafield02Foto ?? this.metafield02Foto,
      metafield03Foto: metafield03Foto ?? this.metafield03Foto,
      tabelaMedida: tabelaMedida ?? this.tabelaMedida,
    );
  }
}

class ProductVariant {
  final int id;
  final String sku;
  final String? size;
  final String? color;
  final int stock;
  final bool? available;
  final double? price;
  final double? compareAtPrice;
  final String? image;

  ProductVariant({
    required this.id,
    required this.sku,
    this.size,
    this.color,
    required this.stock,
    this.available,
    this.price,
    this.compareAtPrice,
    this.image,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? 0,
      sku: json['sku'] ?? '',
      size: json['size'],
      color: json['color'],
      stock: json['stock'] ?? 0,
      available: json['available'],
      price: json['price']?.toDouble(),
      compareAtPrice: json['compareAtPrice']?.toDouble(),
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'size': size,
      'color': color,
      'stock': stock,
      'available': available,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'image': image,
    };
  }
}
