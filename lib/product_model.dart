class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final List<String> imageUrls;
  final bool isAvailable;
  final int stockQuantity;
  final DateTime createdAt;
  final List<String> tags;
  final int popularityScore;
  final List<Review> reviews;
  final ExtraAttributes? extraAttributes;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.imageUrls,
    required this.isAvailable,
    required this.stockQuantity,
    required this.createdAt,
    required this.tags,
    required this.popularityScore,
    required this.reviews,
    this.extraAttributes,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    categoryId: json['categoryId'],
    imageUrls: List<String>.from(json['imageUrls'] ?? []),
    isAvailable: json['isAvailable'] ?? true,
    stockQuantity: json['stockQuantity'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    tags: List<String>.from(json['tags'] ?? []),
    popularityScore: json['popularityScore'] ?? 0,
    reviews:
        (json['reviews'] as List<dynamic>?)
            ?.map((e) => Review.fromJson(e))
            .toList() ??
        [],
    extraAttributes:
        json['extraAttributes'] != null
            ? ExtraAttributes.fromJson(json['extraAttributes'])
            : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'imageUrls': imageUrls,
    'isAvailable': isAvailable,
    'stockQuantity': stockQuantity,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
    'popularityScore': popularityScore,
    'reviews': reviews.map((e) => e.toJson()).toList(),
    'extraAttributes': extraAttributes?.toJson(),
  };
}

class ExtraAttributes {
  final Variant defaultVariant;
  final List<Variant> variants;
  final List<Shape> shapes;

  ExtraAttributes({
    required this.defaultVariant,
    required this.variants,
    required this.shapes,
  });

  factory ExtraAttributes.fromJson(Map<String, dynamic> json) =>
      ExtraAttributes(
        defaultVariant: Variant.fromJson(json['defaultVariant']),
        variants:
            (json['variants'] as List).map((e) => Variant.fromJson(e)).toList(),
        shapes: (json['shapes'] as List).map((e) => Shape.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
    'defaultVariant': defaultVariant.toJson(),
    'variants': variants.map((e) => e.toJson()).toList(),
    'shapes': shapes.map((e) => e.toJson()).toList(),
  };
}

class Variant {
  final String weight;
  final int tier;
  final double price;
  final double? oldPrice;
  final double? discount;
  final String sku;

  Variant({
    required this.weight,
    required this.tier,
    required this.price,
    this.oldPrice,
    this.discount,
    required this.sku,
  });

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
    weight: json['weight'],
    tier: json['tier'],
    price: (json['price'] as num).toDouble(),
    oldPrice:
        json['oldPrice'] != null ? (json['oldPrice'] as num).toDouble() : null,
    discount:
        json['discount'] != null ? (json['discount'] as num).toDouble() : null,
    sku: json['sku'],
  );

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'tier': tier,
    'price': price,
    'oldPrice': oldPrice,
    'discount': discount,
    'sku': sku,
  };
}

class Shape {
  final String name;
  final String imageUrl;

  Shape({required this.name, required this.imageUrl});

  factory Shape.fromJson(Map<String, dynamic> json) =>
      Shape(name: json['name'], imageUrl: json['imageUrl']);

  Map<String, dynamic> toJson() => {'name': name, 'imageUrl': imageUrl};
}

class Review {
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    userId: json['userId'],
    userName: json['userName'],
    rating: (json['rating'] as num).toDouble(),
    comment: json['comment'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
}
