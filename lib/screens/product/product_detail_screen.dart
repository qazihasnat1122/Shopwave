import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../models/product.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageCtrl = PageController();
  String? _selectedSize;
  String? _selectedColor;
  bool _isWishlisted = false;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.sizes.isNotEmpty) _selectedSize = widget.product.sizes.first;
    if (widget.product.colors.isNotEmpty) _selectedColor = widget.product.colors.first;
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _addToCart() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (widget.product.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a size'), backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final item = CartItem(
      id: const Uuid().v4(),
      productId: widget.product.id,
      productName: widget.product.name,
      imageUrl: widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : '',
      price: widget.product.price,
      quantity: _qty,
      selectedSize: _selectedSize,
      selectedColor: _selectedColor,
    );

    context.read<CartBloc>().add(CartItemAdded(userId: authState.user.uid, item: item));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Added to cart!'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: 'View Cart', textColor: Colors.white,
        onPressed: () => context.go('/cart'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isWishlisted = !_isWishlisted),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isWishlisted ? AppTheme.accent : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Image Carousel ───────────────────────────────────
          SizedBox(
            height: 340,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: p.imageUrls.isNotEmpty ? p.imageUrls.length : 1,
                  itemBuilder: (context, i) => CachedNetworkImage(
                    imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls[i] : '',
                    fit: BoxFit.cover, width: double.infinity,
                    placeholder: (_, __) => Container(color: AppTheme.surface2),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surface2,
                      child: const Icon(Icons.image_outlined, size: 48, color: AppTheme.textTertiary),
                    ),
                  ),
                ),
                if (p.isOnSale)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accent, borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('-${p.discountPercentage.toInt()}% OFF',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (p.imageUrls.length > 1)
                  Positioned(
                    bottom: 16, left: 0, right: 0,
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: _pageCtrl,
                        count: p.imageUrls.length,
                        effect: const WormEffect(
                          dotHeight: 6, dotWidth: 6,
                          activeDotColor: AppTheme.primary,
                          dotColor: Colors.white38,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Details ──────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Name
                    Text(p.brand,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12,
                        fontWeight: FontWeight.w600, letterSpacing: 0.06)),
                    const SizedBox(height: 4),
                    Text(p.name, style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 10),

                    // Rating row
                    Row(children: [
                      RatingBarIndicator(
                        rating: p.rating,
                        itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppTheme.warning),
                        itemCount: 5, itemSize: 18,
                        unratedColor: AppTheme.surface3,
                      ),
                      const SizedBox(width: 8),
                      Text('${p.rating} (${p.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodySmall),
                    ]),
                    const SizedBox(height: 16),

                    // Price
                    Row(children: [
                      Text('\$${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primary, fontSize: 28,
                          fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                      if (p.originalPrice != null) ...[
                        const SizedBox(width: 10),
                        Text('\$${p.originalPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppTheme.textTertiary,
                            fontSize: 16, decoration: TextDecoration.lineThrough)),
                      ],
                    ]),
                    const SizedBox(height: 20),

                    // Description
                    Text('Description', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(p.description,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.7)),
                    const SizedBox(height: 20),

                    // Sizes
                    if (p.sizes.isNotEmpty) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Size', style: Theme.of(context).textTheme.titleMedium),
                        const Text('Size Guide', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: p.sizes.map((size) {
                        final isSelected = size == _selectedSize;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSize = size),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48, height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : AppTheme.surface2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(size,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              )),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 20),
                    ],

                    // Colors
                    if (p.colors.isNotEmpty) ...[
                      Text('Color', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, children: p.colors.map((color) {
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : AppTheme.surface2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(color,
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500,
                                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                              )),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 20),
                    ],

                    // Quantity
                    Row(children: [
                      Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      _QtySelector(
                        qty: _qty,
                        onDecrement: () { if (_qty > 1) setState(() => _qty--); },
                        onIncrement: () { if (_qty < 10) setState(() => _qty++); },
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: IconButton(
                icon: const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: p.inStock
                    ? 'Add to Cart · \$${(p.price * _qty).toStringAsFixed(0)}'
                    : 'Out of Stock',
                onPressed: p.inStock ? _addToCart : null,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QtySelector extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement, onIncrement;
  const _QtySelector({required this.qty, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        _QtyBtn(icon: Icons.remove, onTap: onDecrement),
        SizedBox(width: 32, child: Center(
          child: Text('$qty', style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
        )),
        _QtyBtn(icon: Icons.add, onTap: onIncrement),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        alignment: Alignment.center,
        child: Icon(icon, color: AppTheme.textSecondary, size: 18),
      ),
    );
  }
}
