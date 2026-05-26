import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/models.dart';
import '../../repositories/cart_repository.dart';
import '../../utils/app_theme.dart';

// ─────────────────────────── ORDERS LIST ───────────────────────────

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please sign in to view your orders.')),
      );
    }
    final orderRepo = context.read<OrderRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<List<Order>>(
        stream: orderRepo.watchOrders(authState.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 72, color: AppTheme.textTertiary),
                const SizedBox(height: 20),
                Text('No orders yet', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Your order history will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Start Shopping'),
                ),
              ],
            ));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _OrderTile(order: snapshot.data![i]),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface2, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              _StatusBadge(status: order.status),
            ]),
            const SizedBox(height: 8),
            Text(DateFormat('MMM d, yyyy').format(order.createdAt),
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Text('${order.items.length} item${order.items.length > 1 ? 's' : ''} · '
              '\$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
            const SizedBox(height: 8),
            Text(order.shippingAddress.formatted,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending: return AppTheme.warning;
      case OrderStatus.confirmed: return AppTheme.primary;
      case OrderStatus.processing: return AppTheme.primaryLight;
      case OrderStatus.shipped: return AppTheme.success;
      case OrderStatus.delivered: return AppTheme.success;
      case OrderStatus.cancelled: return AppTheme.accent;
    }
  }

  String get _label => status.name[0].toUpperCase() + status.name.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100),
      ),
      child: Text(_label, style: TextStyle(
        color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────── ORDER DETAIL ───────────────────────────

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderRepo = context.read<OrderRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: StreamBuilder<Order>(
        stream: orderRepo.watchOrder(orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final order = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.15), AppTheme.primary.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  _StatusBadge(status: order.status),
                  const SizedBox(height: 12),
                  Text('Order #${order.id.substring(0,8).toUpperCase()}',
                    style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMMM d, yyyy • h:mm a').format(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              const SizedBox(height: 20),

              // Progress Tracker
              _OrderTracker(status: order.status),
              const SizedBox(height: 20),

              // Items
              Text('Items', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface2, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppTheme.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (item.selectedSize != null || item.selectedColor != null)
                        Text(
                          [if (item.selectedSize != null) 'Size ${item.selectedSize}',
                           if (item.selectedColor != null) item.selectedColor!].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  )),
                  Text('×${item.quantity}  \$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ]),
              )),
              const SizedBox(height: 20),

              // Shipping Address
              Text('Shipping To', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface2, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.shippingAddress.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(order.shippingAddress.formatted,
                        style: Theme.of(context).textTheme.bodySmall),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 20),

              // Price Breakdown
              Text('Price Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface2, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(children: [
                  _PriceLine('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
                  _PriceLine('Shipping', order.shipping == 0 ? 'FREE' : '\$${order.shipping.toStringAsFixed(2)}'),
                  if (order.discount > 0)
                    _PriceLine('Discount', '-\$${order.discount.toStringAsFixed(2)}', AppTheme.accent),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 20),
                  _PriceLine('Total', '\$${order.total.toStringAsFixed(2)}', AppTheme.primary, true),
                ]),
              ),

              if (order.status != OrderStatus.cancelled &&
                  order.status != OrderStatus.delivered) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => _cancelOrder(context, orderRepo),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel Order'),
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _cancelOrder(BuildContext context, OrderRepository repo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface1,
        title: const Text('Cancel Order?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Order', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
    if (confirm == true) await repo.cancelOrder(orderId);
  }
}

class _PriceLine extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool bold;
  const _PriceLine(this.label, this.value, [this.color, this.bold = false]);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: TextStyle(
        color: AppTheme.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
      const Spacer(),
      Text(value, style: TextStyle(
        color: color ?? (bold ? AppTheme.textPrimary : AppTheme.textSecondary),
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        fontFamily: bold ? 'Syne' : null,
      )),
    ]),
  );
}

class _OrderTracker extends StatelessWidget {
  final OrderStatus status;
  const _OrderTracker({required this.status});

  static const _steps = [
    OrderStatus.confirmed, OrderStatus.processing,
    OrderStatus.shipped, OrderStatus.delivered,
  ];
  static const _labels = ['Confirmed', 'Processing', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface2, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final isDone = currentIdx > stepIdx;
            return Expanded(child: Container(
              height: 2,
              color: isDone ? AppTheme.success : AppTheme.surface3,
            ));
          }
          final stepIdx = i ~/ 2;
          final isDone = currentIdx >= stepIdx;
          return Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.success : AppTheme.surface3,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle,
                size: isDone ? 16 : 8,
                color: isDone ? Colors.white : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(_labels[stepIdx], style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600,
              color: isDone ? AppTheme.success : AppTheme.textTertiary,
            )),
          ]);
        }),
      ),
    );
  }
}
