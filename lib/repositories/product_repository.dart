import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _collection = 'products';

  // ── Fetch Products ────────────────────────────────────────

  Future<List<Product>> getProducts({
    String? category,
    String? searchQuery,
    String? sortBy,     // 'price_asc' | 'price_desc' | 'rating' | 'newest'
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _db.collection(_collection);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    if (minPrice != null) query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    if (maxPrice != null) query = query.where('price', isLessThanOrEqualTo: maxPrice);

    switch (sortBy) {
      case 'price_asc':   query = query.orderBy('price'); break;
      case 'price_desc':  query = query.orderBy('price', descending: true); break;
      case 'rating':      query = query.orderBy('rating', descending: true); break;
      default:            query = query.orderBy('createdAt', descending: true);
    }

    if (lastDocument != null) query = query.startAfterDocument(lastDocument);
    query = query.limit(limit);

    final snapshot = await query.get();
    var products = snapshot.docs.map(Product.fromFirestore).toList();

    // Client-side search filter (Firestore doesn't support full-text search natively)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      products = products.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q)
      ).toList();
    }

    return products;
  }

  Future<List<Product>> getFeaturedProducts({int limit = 6}) async {
    final snapshot = await _db
        .collection(_collection)
        .where('isFeatured', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(Product.fromFirestore).toList();
  }

  Future<Product> getProductById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) throw Exception('Product not found');
    return Product.fromFirestore(doc);
  }

  Future<void> createProduct(Product product) async {
    // Uses the ID generated or auto-generates if empty
    final docRef = product.id.isEmpty 
        ? _db.collection(_collection).doc() 
        : _db.collection(_collection).doc(product.id);
    
    // Create a copy with the assigned doc ID if it was empty
    final productToSave = product.id.isEmpty 
        ? product.copyWith(id: docRef.id) 
        : product;

    await docRef.set(productToSave.toFirestore());
  }

  Future<List<Product>> getRelatedProducts(Product product, {int limit = 4}) async {
    final snapshot = await _db
        .collection(_collection)
        .where('category', isEqualTo: product.category)
        .where(FieldPath.documentId, isNotEqualTo: product.id)
        .limit(limit)
        .get();
    return snapshot.docs.map(Product.fromFirestore).toList();
  }

  Stream<Product> watchProduct(String id) {
    return _db.collection(_collection).doc(id).snapshots()
        .map(Product.fromFirestore);
  }

  // ── Categories ────────────────────────────────────────────

  Future<List<String>> getCategories() async {
    final snapshot = await _db.collection('categories').orderBy('order').get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((d) => d['name'] as String).toList();
    }
    // Fallback: derive from products
    final products = await _db.collection(_collection)
        .orderBy('category').get();
    return products.docs.map((d) => d['category'] as String).toSet().toList();
  }

  // ── Wishlist ──────────────────────────────────────────────

  Future<void> addToWishlist(String userId, String productId) async {
    await _db.collection('wishlists').doc(userId)
        .collection('items').doc(productId).set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromWishlist(String userId, String productId) async {
    await _db.collection('wishlists').doc(userId)
        .collection('items').doc(productId).delete();
  }

  Future<List<String>> getWishlistIds(String userId) async {
    final snapshot = await _db.collection('wishlists').doc(userId)
        .collection('items').get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  Stream<bool> watchWishlistStatus(String userId, String productId) {
    return _db.collection('wishlists').doc(userId)
        .collection('items').doc(productId).snapshots()
        .map((snap) => snap.exists);
  }

  // ── Reviews ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReviews(String productId) async {
    final snapshot = await _db.collection(_collection).doc(productId)
        .collection('reviews').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<void> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final batch = _db.batch();
    final reviewRef = _db.collection(_collection).doc(productId)
        .collection('reviews').doc();
    batch.set(reviewRef, {
      'userId': userId, 'userName': userName,
      'rating': rating, 'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Update product average rating
    batch.update(_db.collection(_collection).doc(productId), {
      'reviewCount': FieldValue.increment(1),
    });
    await batch.commit();
  }
}
