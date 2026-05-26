// scripts/seed_firestore.js
// Run: node scripts/seed_firestore.js
// Requires: npm install firebase-admin

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json'); // Download from Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const categories = [
  { name: 'Shoes',   order: 1, icon: '👟' },
  { name: 'Bags',    order: 2, icon: '👜' },
  { name: 'Watches', order: 3, icon: '⌚' },
  { name: 'Tees',    order: 4, icon: '👕' },
  { name: 'Jackets', order: 5, icon: '🧥' },
];

const products = [
  {
    name: 'Nike Air Max 270',
    description: 'Premium cushioned sole with React foam technology. Perfect blend of comfort and style for everyday wear. Features a large Air unit in the heel for all-day cushioning.',
    price: 129.99,
    originalPrice: 159.99,
    category: 'Shoes',
    brand: 'Nike',
    imageUrls: [
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=600&fit=crop',
      'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=600&h=600&fit=crop',
    ],
    sizes: ['7', '8', '9', '10', '11', '12'],
    colors: ['Black/White', 'Red/Black', 'White/Blue'],
    rating: 4.8,
    reviewCount: 2100,
    stock: 45,
    isFeatured: true,
  },
  {
    name: 'Adidas Ultraboost 22',
    description: 'Responsive Boost midsole with Primeknit upper. Designed for runners who want maximum energy return and comfort over long distances.',
    price: 149.99,
    originalPrice: null,
    category: 'Shoes',
    brand: 'Adidas',
    imageUrls: [
      'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=600&h=600&fit=crop',
    ],
    sizes: ['7', '8', '9', '10', '11'],
    colors: ['Core Black', 'Cloud White'],
    rating: 4.6,
    reviewCount: 1450,
    stock: 30,
    isFeatured: false,
  },
  {
    name: 'Leather Tote Bag',
    description: 'Handcrafted genuine leather tote with spacious interior and multiple pockets. Perfect for work or weekend outings.',
    price: 89.00,
    originalPrice: 120.00,
    category: 'Bags',
    brand: 'Fossil',
    imageUrls: [
      'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600&h=600&fit=crop',
    ],
    sizes: ['One Size'],
    colors: ['Brown', 'Black', 'Tan'],
    rating: 4.5,
    reviewCount: 834,
    stock: 20,
    isFeatured: true,
  },
  {
    name: 'Classic Minimalist Watch',
    description: 'Swiss movement quartz watch with sapphire crystal glass. Water resistant to 50m. Premium stainless steel case and genuine leather strap.',
    price: 249.00,
    originalPrice: null,
    category: 'Watches',
    brand: 'Seiko',
    imageUrls: [
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&h=600&fit=crop',
    ],
    sizes: ['One Size'],
    colors: ['Silver', 'Gold', 'Rose Gold'],
    rating: 4.9,
    reviewCount: 3200,
    stock: 15,
    isFeatured: true,
  },
  {
    name: 'Premium Cotton Tee',
    description: '100% Pima cotton t-shirt with a relaxed fit. Pre-shrunk, anti-pilling fabric that stays soft wash after wash.',
    price: 45.00,
    originalPrice: 59.99,
    category: 'Tees',
    brand: 'Everlane',
    imageUrls: [
      'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=600&h=600&fit=crop',
    ],
    sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
    colors: ['White', 'Black', 'Navy', 'Grey'],
    rating: 4.4,
    reviewCount: 620,
    stock: 100,
    isFeatured: false,
  },
  {
    name: 'Crossbody Messenger Bag',
    description: 'Lightweight canvas crossbody bag with padded laptop sleeve and multiple organizer pockets. Adjustable strap for comfort.',
    price: 65.00,
    originalPrice: 85.00,
    category: 'Bags',
    brand: 'Herschel',
    imageUrls: [
      'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&h=600&fit=crop',
    ],
    sizes: ['One Size'],
    colors: ['Navy', 'Black', 'Olive'],
    rating: 4.3,
    reviewCount: 445,
    stock: 35,
    isFeatured: false,
  },
  {
    name: 'Bomber Jacket',
    description: 'Classic bomber jacket with ribbed cuffs and hem. Water-resistant outer shell with warm fleece lining. Perfect for transitional weather.',
    price: 189.00,
    originalPrice: 240.00,
    category: 'Jackets',
    brand: 'Alpha Industries',
    imageUrls: [
      'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&h=600&fit=crop',
    ],
    sizes: ['XS', 'S', 'M', 'L', 'XL'],
    colors: ['Olive', 'Black', 'Navy'],
    rating: 4.7,
    reviewCount: 980,
    stock: 25,
    isFeatured: true,
  },
];

const coupons = [
  { code: 'WELCOME10', discount: 10, type: 'percentage',
    expiresAt: new Date('2025-12-31') },
  { code: 'SAVE20', discount: 20, type: 'fixed',
    expiresAt: new Date('2025-12-31') },
  { code: 'SHOPWAVE15', discount: 15, type: 'percentage',
    expiresAt: new Date('2025-12-31') },
];

async function seed() {
  console.log('🌱 Seeding Firestore...');

  // Categories
  for (const cat of categories) {
    await db.collection('categories').doc(cat.name.toLowerCase()).set(cat);
    console.log(`  ✓ Category: ${cat.name}`);
  }

  // Products
  for (const product of products) {
    const ref = await db.collection('products').add({
      ...product,
      tags: {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  ✓ Product: ${product.name} (${ref.id})`);
  }

  // Coupons
  for (const coupon of coupons) {
    await db.collection('coupons').doc(coupon.code).set({
      ...coupon,
      expiresAt: admin.firestore.Timestamp.fromDate(coupon.expiresAt),
    });
    console.log(`  ✓ Coupon: ${coupon.code}`);
  }

  console.log('\n✅ Firestore seeded successfully!');
  process.exit(0);
}

seed().catch(err => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
