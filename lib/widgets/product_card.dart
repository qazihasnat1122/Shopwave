import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';

// ─────────────────────────── PRODUCT CARD ───────────────────────────

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppTheme.surface3, highlightColor: AppTheme.surface2,
                      child: Container(color: AppTheme.surface3),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surface3,
                      child: const Icon(Icons.image_outlined,
                        color: AppTheme.textTertiary, size: 32),
                    ),
                  ),
                  if (product.isOnSale)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent, borderRadius: BorderRadius.circular(6)),
                        child: Text('-${product.discountPercentage.toInt()}%',
                          style: const TextStyle(color: Colors.white,
                            fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (!product.inStock)
                    Positioned.fill(child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(child: Text('Sold Out',
                        style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 12))),
                    )),
                  Positioned(top: 8, right: 8,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded,
                        color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.brand,
                          style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w600, letterSpacing: 0.06)),
                        const SizedBox(height: 2),
                        Text(product.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('\$${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primary, fontWeight: FontWeight.w800,
                              fontSize: 14, fontFamily: 'Syne')),
                          if (product.originalPrice != null)
                            Text('\$${product.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.textTertiary, fontSize: 10,
                                decoration: TextDecoration.lineThrough)),
                        ]),
                        Row(children: [
                          const Icon(Icons.star_rounded, color: AppTheme.warning, size: 12),
                          const SizedBox(width: 2),
                          Text(product.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
