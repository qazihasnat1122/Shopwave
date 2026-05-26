import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────── USER ───────────────────────────

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final Address? defaultAddress;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.defaultAddress,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: d['email'] ?? '',
      displayName: d['displayName'] ?? '',
      photoUrl: d['photoUrl'],
      phoneNumber: d['phoneNumber'],
      defaultAddress: d['defaultAddress'] != null
          ? Address.fromMap(d['defaultAddress'])
          : null,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'phoneNumber': phoneNumber,
    'defaultAddress': defaultAddress?.toMap(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AppUser copyWith({
    String? displayName, String? photoUrl, String? phoneNumber,
    Address? defaultAddress,
  }) => AppUser(
    uid: uid, email: email, createdAt: createdAt,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    defaultAddress: defaultAddress ?? this.defaultAddress,
  );

  @override
  List<Object?> get props => [uid, email];
}

// ─────────────────────────── ADDRESS ───────────────────────────

class Address extends Equatable {
  final String fullName;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String country;

  const Address({
    required this.fullName, required this.street, required this.city,
    required this.state, required this.zip, required this.country,
  });

  factory Address.fromMap(Map<String, dynamic> m) => Address(
    fullName: m['fullName'] ?? '', street: m['street'] ?? '',
    city: m['city'] ?? '', state: m['state'] ?? '',
    zip: m['zip'] ?? '', country: m['country'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'fullName': fullName, 'street': street, 'city': city,
    'state': state, 'zip': zip, 'country': country,
  };

  String get formatted => '$street, $city, $state $zip, $country';

  @override
  List<Object?> get props => [street, city, zip];
}

// ─────────────────────────── CART ITEM ───────────────────────────

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
  });

  double get total => price * quantity;

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      productId: d['productId'] ?? '',
      productName: d['productName'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      quantity: d['quantity'] ?? 1,
      selectedSize: d['selectedSize'],
      selectedColor: d['selectedColor'],
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> d) {
    return CartItem(
      id: (d['id'] as String?) ?? (d['productId'] as String? ?? ''),
      productId: d['productId'] ?? '',
      productName: d['productName'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      quantity: d['quantity'] ?? 1,
      selectedSize: d['selectedSize'],
      selectedColor: d['selectedColor'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'productId': productId, 'productName': productName,
    'imageUrl': imageUrl, 'price': price, 'quantity': quantity,
    'selectedSize': selectedSize, 'selectedColor': selectedColor,
  };

  CartItem copyWith({int? quantity}) => CartItem(
    id: id, productId: productId, productName: productName,
    imageUrl: imageUrl, price: price, selectedSize: selectedSize,
    selectedColor: selectedColor, quantity: quantity ?? this.quantity,
  );

  @override
  List<Object?> get props => [id, productId, selectedSize, selectedColor];
}

// ─────────────────────────── ORDER ───────────────────────────

enum OrderStatus { pending, confirmed, processing, shipped, delivered, cancelled }

class Order extends Equatable {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final Address shippingAddress;
  final OrderStatus status;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id, required this.userId, required this.items,
    required this.subtotal, required this.shipping, required this.discount,
    required this.total, required this.shippingAddress, required this.status,
    this.stripePaymentIntentId, required this.createdAt, this.updatedAt,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: d['userId'] ?? '',
      items: (d['items'] as List<dynamic>?)
          ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (d['subtotal'] ?? 0).toDouble(),
      shipping: (d['shipping'] ?? 0).toDouble(),
      discount: (d['discount'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      shippingAddress: Address.fromMap(d['shippingAddress'] ?? {}),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == d['status'], orElse: () => OrderStatus.pending,
      ),
      stripePaymentIntentId: d['stripePaymentIntentId'],
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: d['updatedAt'] != null
          ? (d['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'items': items.map((i) => i.toFirestore()).toList(),
    'subtotal': subtotal, 'shipping': shipping,
    'discount': discount, 'total': total,
    'shippingAddress': shippingAddress.toMap(),
    'status': status.name,
    'stripePaymentIntentId': stripePaymentIntentId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  @override
  List<Object?> get props => [id, status];
}
