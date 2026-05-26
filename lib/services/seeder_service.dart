import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeederService {
  static Future<void> seedDatabase() async {
    final db = FirebaseFirestore.instance;

    final categories = [
      {'name': 'Electronics', 'order': 1},
      {'name': 'Clothing', 'order': 2},
      {'name': 'Home', 'order': 3},
      {'name': 'Sports', 'order': 4},
    ];

    final products = [
      {
        'name': 'Wireless Noise-Canceling Headphones',
        'brand': 'SoundMax',
        'description': 'Experience premium sound quality with active noise cancellation and 30-hour battery life.',
        'price': 299.99,
        'category': 'Electronics',
        'imageUrls': [
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=1000&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1484704849700-f032a568e944?q=80&w=1000&auto=format&fit=crop'
        ],
        'rating': 4.8,
        'reviewCount': 124,
        'isFeatured': true,
        'stock': 45,
        'sizes': [],
        'colors': ['Black', 'Silver'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Minimalist Cotton T-Shirt',
        'brand': 'UrbanWear',
        'description': 'Ultra-soft, breathable 100% organic cotton t-shirt for everyday comfort.',
        'price': 24.99,
        'category': 'Clothing',
        'imageUrls': [
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=1000&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?q=80&w=1000&auto=format&fit=crop'
        ],
        'rating': 4.5,
        'reviewCount': 89,
        'isFeatured': true,
        'stock': 120,
        'sizes': ['S', 'M', 'L', 'XL'],
        'colors': ['White', 'Black', 'Navy'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Smart Fitness Watch Series 7',
        'brand': 'TechFit',
        'description': 'Track your health, workouts, and receive notifications directly on your wrist. Water-resistant up to 50m.',
        'price': 199.50,
        'category': 'Electronics',
        'imageUrls': [
          'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?q=80&w=1000&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?q=80&w=1000&auto=format&fit=crop'
        ],
        'rating': 4.7,
        'reviewCount': 210,
        'isFeatured': true,
        'stock': 30,
        'sizes': [],
        'colors': ['Midnight', 'Starlight'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Premium Leather Sneakers',
        'brand': 'Stride',
        'description': 'Handcrafted genuine leather sneakers combining classic style with modern comfort technology.',
        'price': 129.00,
        'category': 'Clothing',
        'imageUrls': [
          'https://images.unsplash.com/photo-1560769629-975ec94e6a86?q=80&w=1000&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1549298916-b41d501d3772?q=80&w=1000&auto=format&fit=crop'
        ],
        'rating': 4.6,
        'reviewCount': 56,
        'isFeatured': false,
        'stock': 85,
        'sizes': ['8', '9', '10', '11', '12'],
        'colors': ['White', 'Brown'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Ceramic Pour-Over Coffee Maker',
        'brand': 'BrewArt',
        'description': 'Elegant ceramic design for the perfect artisanal cup of coffee every morning.',
        'price': 45.00,
        'category': 'Home',
        'imageUrls': [
          'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?q=80&w=1000&auto=format&fit=crop'
        ],
        'rating': 4.9,
        'reviewCount': 34,
        'isFeatured': true,
        'stock': 15,
        'sizes': [],
        'colors': ['Matte Black', 'Cream'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Professional Yoga Mat',
        'brand': 'Zenith',
        'description': 'Eco-friendly, non-slip 6mm thick yoga mat for optimal cushioning and joint support.',
        'price': 65.00,
        'category': 'Sports',
        'imageUrls': [
          'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?q=80&w=1000&auto=format&fit=crop'
        ],
        'rating': 4.4,
        'reviewCount': 112,
        'isFeatured': false,
        'stock': 60,
        'sizes': [],
        'colors': ['Purple', 'Teal', 'Charcoal'],
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    final batch = db.batch();

    // 1. Seed Categories
    for (final cat in categories) {
      final docRef = db.collection('categories').doc(cat['name'].toString().toLowerCase());
      batch.set(docRef, cat);
    }

    // 2. Seed Products
    for (final prod in products) {
      final docRef = db.collection('products').doc();
      batch.set(docRef, prod);
    }

    await batch.commit();
    debugPrint('✅ Database successfully seeded with 6 products and 4 categories!');
  }
}
