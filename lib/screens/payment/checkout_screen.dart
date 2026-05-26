import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../models/models.dart';
import '../../repositories/cart_repository.dart';
import '../../services/stripe_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

// ─────────────────────────── CHECKOUT ───────────────────────────

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'United States');
  bool _isProcessing = false;
  int _currentStep = 0;

  @override
  void dispose() {
    for (final c in [_nameCtrl,_streetCtrl,_cityCtrl,_stateCtrl,_zipCtrl,_countryCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final authState = context.read<AuthBloc>().state as AuthAuthenticated;
      final cartState = context.read<CartBloc>().state as CartLoaded;
      final stripeService = context.read<StripeService>();
      final orderRepo = context.read<OrderRepository>();

      // Create order document first
      final orderId = const Uuid().v4();
      final address = Address(
        fullName: _nameCtrl.text, street: _streetCtrl.text,
        city: _cityCtrl.text, state: _stateCtrl.text,
        zip: _zipCtrl.text, country: _countryCtrl.text,
      );

      final order = Order(
        id: orderId, userId: authState.user.uid,
        items: cartState.items, subtotal: cartState.subtotal,
        shipping: cartState.shipping, discount: cartState.couponDiscount,
        total: cartState.total, shippingAddress: address,
        status: OrderStatus.pending, createdAt: DateTime.now(),
      );

      final firestoreOrderId = await orderRepo.createOrder(order);

      // Process Stripe payment
      await stripeService.processPayment(
        amount: cartState.total,
        currency: 'usd',
        orderId: firestoreOrderId,
      );

      // Update order with payment info
      await orderRepo.updateOrderStatus(firestoreOrderId, OrderStatus.confirmed);

      // Ensure widget still mounted before using context
      if (!mounted) return;

      // Clear cart
      context.read<CartBloc>().add(CartCleared(userId: authState.user.uid));
      context.go('/payment/success', extra: firestoreOrderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('cancelled')
            ? 'Payment cancelled' : 'Payment failed. Please try again.'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.read<CartBloc>().state;
    final cart = cartState is CartLoaded ? cartState : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (i) => setState(() => _currentStep = i),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(children: [
                if (details.stepIndex < 1)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continue'),
                  ),
                if (details.stepIndex == 1)
                  AppButton(
                    label: 'Pay \$${cart?.total.toStringAsFixed(2) ?? '0.00'}',
                    isLoading: _isProcessing,
                    onPressed: _processPayment,
                  ),
                if (details.stepIndex > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ]),
            );
          },
          onStepContinue: () {
            if (_currentStep == 0) setState(() => _currentStep = 1);
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          steps: [
            // ── Step 1: Shipping Address ────────────────────
            Step(
              title: const Text('Shipping Address'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(children: [
                AppTextField(
                  controller: _nameCtrl, label: 'Full Name',
                  hint: 'John Doe', prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _streetCtrl, label: 'Street Address',
                  hint: '123 Main St', prefixIcon: Icons.home_outlined,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: AppTextField(
                    controller: _cityCtrl, label: 'City', hint: 'New York',
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(
                    controller: _stateCtrl, label: 'State', hint: 'NY',
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: AppTextField(
                    controller: _zipCtrl, label: 'ZIP', hint: '10001',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(
                    controller: _countryCtrl, label: 'Country',
                    hint: 'United States',
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  )),
                ]),
              ]),
            ),

            // ── Step 2: Payment ─────────────────────────────
            Step(
              title: const Text('Payment'),
              isActive: _currentStep >= 1,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cart != null) _OrderSummaryRow(cart: cart),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text(
                        'Payment is secured by Stripe. Your card details are never stored.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap "Pay" to enter your card details via Stripe.',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  final CartLoaded cart;
  const _OrderSummaryRow({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface2, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        _Line('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
        _Line('Shipping', cart.shipping == 0 ? 'FREE' : '\$${cart.shipping.toStringAsFixed(2)}'),
        if (cart.couponDiscount > 0)
          _Line('Discount', '-\$${cart.couponDiscount.toStringAsFixed(2)}', AppTheme.accent),
        Divider(color: Colors.white.withValues(alpha: 0.07), height: 20),
        _Line('Total', '\$${cart.total.toStringAsFixed(2)}', AppTheme.primary, true),
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool bold;
  const _Line(this.label, this.value, [this.color, this.bold = false]);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: TextStyle(
        color: AppTheme.textSecondary, fontSize: bold ? 15 : 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      )),
      const Spacer(),
      Text(value, style: TextStyle(
        color: color ?? (bold ? AppTheme.textPrimary : AppTheme.textSecondary),
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        fontSize: bold ? 15 : 13, fontFamily: bold ? 'Syne' : null,
      )),
    ]),
  );
}

// ─────────────────────────── PAYMENT SUCCESS ───────────────────────────

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;
  const PaymentSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 56),
                ),
                const SizedBox(height: 28),
                Text('Order Placed! 🎉',
                  style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Your order has been confirmed. You\'ll receive an email with tracking details.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2, borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Order #${orderId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'Syne', fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
                const SizedBox(height: 40),
                AppButton(
                  label: 'Track My Order',
                  onPressed: () => context.go('/orders/$orderId'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Continue Shopping',
                    style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
