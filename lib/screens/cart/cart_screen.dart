import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _showCoupon = false;

  @override
  void dispose() { _couponCtrl.dispose(); super.dispose(); }

  String get _userId {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated ? auth.user.uid : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final count = state is CartLoaded ? state.itemCount : 0;
            return Text('My Cart${count > 0 ? ' ($count)' : ''}');
          },
        ),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (_, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return TextButton(
                  onPressed: () => context.read<CartBloc>().add(CartCleared(userId: _userId)),
                  child: const Text('Clear', style: TextStyle(color: AppTheme.accent)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: AppTheme.accent,
              behavior: SnackBarBehavior.floating,
            ));
          }
          if (state is CartOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (state is CartLoaded && state.items.isEmpty || state is CartInitial) {
            return _EmptyCart();
          }

          if (state is CartLoaded) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...state.items.map((item) => _CartItemTile(
                        item: item, userId: _userId,
                      )),

                      // Coupon Section
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => _showCoupon = !_showCoupon),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.local_offer_outlined, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            const Text('Have a coupon code?',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Icon(_showCoupon ? Icons.expand_less : Icons.expand_more,
                              color: AppTheme.textTertiary),
                          ]),
                        ),
                      ),
                      if (_showCoupon) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _couponCtrl,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_couponCtrl.text.isNotEmpty) {
                                context.read<CartBloc>().add(CartCouponApplied(
                                  userId: _userId, couponCode: _couponCtrl.text,
                                ));
                              }
                            },
                            child: const Text('Apply'),
                          ),
                        ]),
                      ],

                      // Order Summary
                      const SizedBox(height: 16),
                      _OrderSummary(state: state),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Checkout Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: AppButton(
                    label: 'Checkout · \$${state.total.toStringAsFixed(2)}',
                    onPressed: () => context.push('/checkout'),
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final String userId;
  const _CartItemTile({required this.item, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.accent),
      ),
      onDismissed: (_) => context.read<CartBloc>().add(
        CartItemRemoved(userId: userId, itemId: item.id),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 72, height: 72, fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppTheme.surface3),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.surface3,
                child: const Icon(Icons.image_outlined, color: AppTheme.textTertiary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                [if (item.selectedSize != null) 'Size ${item.selectedSize}',
                 if (item.selectedColor != null) item.selectedColor!].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('\$${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w800,
                    fontSize: 15, fontFamily: 'Syne')),
                const Spacer(),
                _QtyControl(item: item, userId: userId),
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final CartItem item;
  final String userId;
  const _QtyControl({required this.item, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Btn(
        icon: item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
        color: item.quantity == 1 ? AppTheme.accent : AppTheme.textSecondary,
        onTap: () => context.read<CartBloc>().add(
          CartItemQuantityUpdated(userId: userId, itemId: item.id, quantity: item.quantity - 1),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('${item.quantity}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
      _Btn(
        icon: Icons.add,
        onTap: () => context.read<CartBloc>().add(
          CartItemQuantityUpdated(userId: userId, itemId: item.id, quantity: item.quantity + 1),
        ),
      ),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _Btn({required this.icon, required this.onTap, this.color = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: AppTheme.surface3, borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}

class _OrderSummary extends StatelessWidget {
  final CartLoaded state;
  const _OrderSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        _Row('Subtotal', '\$${state.subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 10),
        _Row('Shipping', state.shipping == 0 ? 'FREE' : '\$${state.shipping.toStringAsFixed(2)}',
          valueColor: state.shipping == 0 ? AppTheme.success : null),
        if (state.couponDiscount > 0) ...[
          const SizedBox(height: 10),
          _Row('Discount (${state.couponCode})',
            '-\$${state.couponDiscount.toStringAsFixed(2)}',
            valueColor: AppTheme.accent),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
        ),
        Row(children: [
          const Text('Total', style: TextStyle(
            fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('\$${state.total.toStringAsFixed(2)}', style: const TextStyle(
            fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: Theme.of(context).textTheme.bodyMedium),
    const Spacer(),
    Text(value, style: TextStyle(
      fontWeight: FontWeight.w600,
      color: valueColor ?? AppTheme.textPrimary,
    )),
  ]);
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.textTertiary),
        const SizedBox(height: 20),
        Text('Your cart is empty', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Add products to start shopping', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go('/'),
          child: const Text('Start Shopping'),
        ),
      ],
    ));
  }
}
