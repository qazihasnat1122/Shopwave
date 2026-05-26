import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../models/product.dart';
import '../../utils/app_theme.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final displayName = authState is AuthAuthenticated
        ? authState.user.displayName
        : 'there';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good morning,',
                            style: Theme.of(context).textTheme.bodySmall),
                          Text('$firstName 👋',
                            style: Theme.of(context).textTheme.displayMedium),
                        ],
                      ),
                    ),
                    _NotificationBell(),
                    const SizedBox(width: 12),
                    _Avatar(
                      name: authState is AuthAuthenticated
                          ? authState.user.displayName
                          : 'U',
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.textTertiary, size: 20),
                        const SizedBox(width: 10),
                        Text('Search products, brands...',
                          style: Theme.of(context).textTheme.bodyMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main Content ─────────────────────────────────────
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) return _LoadingSliver();
                if (state is ProductError) return _ErrorSliver(message: state.message);
                if (state is ProductLoaded) return _ContentSliver(state: state);
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentSliver extends StatelessWidget {
  final ProductLoaded state;
  const _ContentSliver({required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Categories ─────────────────────────────────────
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text('Categories', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = state.categories[i];
              final isActive = cat == state.selectedCategory;
              return GestureDetector(
                onTap: () => context.read<ProductBloc>().add(CategoryChanged(category: cat)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary : AppTheme.surface2,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isActive ? AppTheme.primary : Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Text(cat,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    )),
                ),
              );
            },
          ),
        ),

        // ── Featured Banner ────────────────────────────────
        if (state.featured.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Featured', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.go('/search'),
                  child: const Text('See all →', style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _FeaturedCard(product: state.featured[i]),
            ),
          ),
        ],

        // ── Products Grid ──────────────────────────────────
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('All Products', style: Theme.of(context).textTheme.titleLarge),
              Text('${state.products.length} items',
                style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14, crossAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: state.products.length,
            itemBuilder: (context, i) => ProductCard(product: state.products[i]),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Product product;
  const _FeaturedCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
              fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              placeholder: (_, __) => _shimmerBox(),
              errorWidget: (_, __, ___) => Container(color: AppTheme.surface3,
                child: const Icon(Icons.image_outlined, color: AppTheme.textTertiary)),
            ),
            // Gradient overlay
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
              ),
            ))),
            // Info
            Positioned(bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.isOnSale)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent, borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('-${product.discountPercentage.toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    Text(product.name, style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('\$${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.primary,
                          fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text('\$${product.originalPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppTheme.textTertiary,
                            fontSize: 12, decoration: TextDecoration.lineThrough)),
                      ],
                    ]),
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

Widget _shimmerBox() => Shimmer.fromColors(
  baseColor: AppTheme.surface2, highlightColor: AppTheme.surface3,
  child: Container(color: AppTheme.surface2),
);

class _LoadingSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Shimmer.fromColors(
            baseColor: AppTheme.surface2, highlightColor: AppTheme.surface3,
            child: Container(decoration: BoxDecoration(
              color: AppTheme.surface2, borderRadius: BorderRadius.circular(20))),
          ),
          childCount: 6,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.72,
        ),
      ),
    );
  }
}

class _ErrorSliver extends StatelessWidget {
  final String message;
  const _ErrorSliver({required this.message});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.accent, size: 48),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.read<ProductBloc>().add(ProductsLoaded()),
            child: const Text('Retry'),
          ),
        ],
      )),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined, size: 24),
        onPressed: () {},
      ),
      Positioned(
        top: 8, right: 8,
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
        ),
      ),
    ]);
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
        shape: BoxShape.circle,
      ),
      child: Center(child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
      )),
    );
  }
}
