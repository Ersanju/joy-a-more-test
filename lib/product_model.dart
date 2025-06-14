import 'package:cloud_firestore/cloud_firestore.dart';

class CakeProduct {
  final String id;
  final String name;
  final List<String> productDescription;
  final List<String> careInstruction;
  final List<String> deliveryInformation;
  final String categoryId;
  final List<String> imageUrls;
  final bool isAvailable;
  final int stockQuantity;
  final List<String> tags;
  final int popularityScore;
  final List<Review> reviews;
  final ExtraAttributes? extraAttributes;
  final DateTime createdAt;

  CakeProduct({
    required this.id,
    required this.name,
    required this.productDescription,
    required this.careInstruction,
    required this.deliveryInformation,
    required this.categoryId,
    required this.imageUrls,
    required this.isAvailable,
    required this.stockQuantity,
    required this.tags,
    required this.popularityScore,
    required this.reviews,
    this.extraAttributes,
    required this.createdAt,
  });

  factory CakeProduct.fromJson(Map<String, dynamic> json) => CakeProduct(
    id: json['id'],
    name: json['name'],
    productDescription: List<String>.from(json['productDescription'] ?? []),
    careInstruction: List<String>.from(json['careInstruction'] ?? []),
    deliveryInformation:
    List<String>.from(json['deliveryInformation'] ?? []),
    categoryId: json['categoryId'],
    imageUrls: List<String>.from(json['imageUrls'] ?? []),
    isAvailable: json['isAvailable'] ?? true,
    stockQuantity: json['stockQuantity'] ?? 0,
    tags: List<String>.from(json['tags'] ?? []),
    popularityScore: json['popularityScore'] ?? 0,
    reviews: (json['reviews'] as List?)
        ?.map((e) => Review.fromJson(e))
        .toList() ??
        [],
    extraAttributes: json['extraAttributes'] != null
        ? ExtraAttributes.fromJson(json['extraAttributes'])
        : null,
    createdAt: (json['createdAt'] is Timestamp)
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'productDescription': productDescription,
    'careInstruction': careInstruction,
    'deliveryInformation': deliveryInformation,
    'categoryId': categoryId,
    'imageUrls': imageUrls,
    'isAvailable': isAvailable,
    'stockQuantity': stockQuantity,
    'tags': tags,
    'popularityScore': popularityScore,
    'reviews': reviews.map((e) => e.toJson()).toList(),
    'extraAttributes': extraAttributes?.toJson(),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class Review {
  final String userId;
  final String userName;
  final List<String> imageUrls;
  final double rating;
  final String comment;
  final String occasion;
  final String place;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.imageUrls,
    required this.rating,
    required this.comment,
    required this.occasion,
    required this.place,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    userId: json['userId'] ?? '',
    userName: json['userName'] ?? '',
    imageUrls: List<String>.from(json['imageUrls'] ?? []),
    rating: (json['rating'] is num)
        ? (json['rating'] as num).toDouble()
        : double.tryParse(json['rating'].toString()) ?? 0.0,
    comment: json['comment'] ?? '',
    occasion: json['occasion'] ?? '',
    place: json['place'] ?? '',
    createdAt: (json['createdAt'] is Timestamp)
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.tryParse(json['createdAt'].toString()) ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'imageUrls': imageUrls,
    'rating': rating,
    'comment': comment,
    'occasion': occasion,
    'place': place,
    'createdAt': Timestamp.fromDate(createdAt),
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
        variants: List<Variant>.from(
            (json['variants'] as List).map((e) => Variant.fromJson(e))),
        shapes: List<Shape>.from(
            (json['shapes'] as List).map((e) => Shape.fromJson(e))),
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
    oldPrice: json['oldPrice'] != null
        ? (json['oldPrice'] as num).toDouble()
        : null,
    discount: json['discount'] != null
        ? (json['discount'] as num).toDouble()
        : null,
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

  Shape({
    required this.name,
    required this.imageUrl,
  });

  factory Shape.fromJson(Map<String, dynamic> json) => Shape(
    name: json['name'],
    imageUrl: json['imageUrl'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'imageUrl': imageUrl,
  };
}
