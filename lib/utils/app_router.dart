import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_bloc.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/search_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/payment/checkout_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/admin/admin_product_upload_screen.dart';
import '../models/product.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;
        final isLoadingOrInitial =
            authState is AuthInitial || authState is AuthLoading;
        final isAuthRoute =
            state.matchedLocation.startsWith('/auth');

        // While auth is resolving, don't redirect
        if (isLoadingOrInitial) return null;

        // If not authenticated and not on an auth route, go to login
        if (!isAuthenticated && !isAuthRoute) return '/auth/login';

        // If already authenticated and trying to access auth pages, go home
        if (isAuthenticated && isAuthRoute) return '/';

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: '/auth/login',
          name: 'login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          name: 'register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          name: 'forgotPassword',
          builder: (_, __) => const ForgotPasswordScreen(),
        ),

        // Main shell with bottom nav
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (_, __) => const HomeScreen(),
            ),
            GoRoute(
              path: '/search',
              name: 'search',
              builder: (_, __) => const SearchScreen(),
            ),
            GoRoute(
              path: '/cart',
              name: 'cart',
              builder: (_, __) => const CartScreen(),
            ),
            GoRoute(
              path: '/orders',
              name: 'orders',
              builder: (_, __) => const OrdersScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),

        // Full-screen routes (no bottom nav)
        GoRoute(
          path: '/product/:id',
          name: 'productDetail',
          builder: (context, state) {
            final product = state.extra as Product;
            return ProductDetailScreen(product: product);
          },
        ),
        GoRoute(
          path: '/checkout',
          name: 'checkout',
          builder: (_, __) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/payment/success',
          name: 'paymentSuccess',
          builder: (context, state) {
            final orderId = state.extra as String;
            return PaymentSuccessScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/orders/:id',
          name: 'orderDetail',
          builder: (context, state) {
            final orderId = state.pathParameters['id']!;
            return OrderDetailScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/admin/products/add',
          name: 'adminProductUpload',
          builder: (_, __) => const AdminProductUploadScreen(),
        ),
      ],
    );
  }
}
