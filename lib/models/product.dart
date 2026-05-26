import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String brand;
  final List<String> imageUrls;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool isFeatured;
  final Map<String, dynamic> tags;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.brand,
    required this.imageUrls,
    required this.sizes,
    required this.colors,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    this.isFeatured = false,
    this.tags = const {},
    required this.createdAt,
  });

  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  bool get isOnSale => discountPercentage > 0;
  bool get inStock => stock > 0;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      stock: data['stock'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      tags: Map<String, dynamic>.from(data['tags'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'price': price,
    'originalPrice': originalPrice,
    'category': category,
    'brand': brand,
    'imageUrls': imageUrls,
    'sizes': sizes,
    'colors': colors,
    'rating': rating,
    'reviewCount': reviewCount,
    'stock': stock,
    'isFeatured': isFeatured,
    'tags': tags,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  Product copyWith({
    String? id, String? name, String? description, double? price,
    double? originalPrice, String? category, String? brand,
    List<String>? imageUrls, List<String>? sizes, List<String>? colors,
    double? rating, int? reviewCount, int? stock, bool? isFeatured,
    Map<String, dynamic>? tags, DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id, name: name ?? this.name,
      description: description ?? this.description, price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category, brand: brand ?? this.brand,
      imageUrls: imageUrls ?? this.imageUrls, sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors, rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount, stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured, tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, price, stock];
}
