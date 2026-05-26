import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/models.dart';

// ─────────────────────────── CART ───────────────────────────

class CartRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _cartRef(String userId) =>
      _db.collection('carts').doc(userId).collection('items');

  Stream<List<CartItem>> watchCart(String userId) {
    return _cartRef(userId).snapshots().map((snap) =>
        snap.docs.map(CartItem.fromFirestore).toList());
  }

  Future<void> addItem(String userId, CartItem item) async {
    // Check if same product+size+color already in cart
    final existing = await _cartRef(userId)
        .where('productId', isEqualTo: item.productId)
        .where('selectedSize', isEqualTo: item.selectedSize)
        .where('selectedColor', isEqualTo: item.selectedColor)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final currentQty = (doc.data() as Map)['quantity'] as int;
      await doc.reference.update({'quantity': currentQty + item.quantity});
    } else {
      await _cartRef(userId).add(item.toFirestore());
    }
  }

  Future<void> updateQuantity(String userId, String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(userId, itemId);
      return;
    }
    await _cartRef(userId).doc(itemId).update({'quantity': quantity});
  }

  Future<void> removeItem(String userId, String itemId) async {
    await _cartRef(userId).doc(itemId).delete();
  }

  Future<void> clearCart(String userId) async {
    final snapshot = await _cartRef(userId).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> applyCoupon(String userId, String code) async {
    // Validate coupon code from Firestore
    final couponDoc = await _db.collection('coupons').doc(code.toUpperCase()).get();
    if (!couponDoc.exists) throw Exception('Invalid coupon code');

    final data = couponDoc.data()!;
    final expiry = (data['expiresAt'] as Timestamp).toDate();
    if (expiry.isBefore(DateTime.now())) throw Exception('Coupon expired');

    await _db.collection('carts').doc(userId).set({
      'couponCode': code.toUpperCase(),
      'couponDiscount': data['discount'],
      'couponType': data['type'], // 'percentage' | 'fixed'
    }, SetOptions(merge: true));
  }
}

// ─────────────────────────── ORDER ───────────────────────────

class OrderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Order>> watchOrders(String userId) {
    return _db.collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Order.fromFirestore).toList());
  }

  Future<Order> getOrder(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists) throw Exception('Order not found');
    return Order.fromFirestore(doc);
  }

  Future<String> createOrder(Order order) async {
    final ref = await _db.collection('orders').add(order.toFirestore());
    return ref.id;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  Stream<Order> watchOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots()
        .map(Order.fromFirestore);
  }
}
