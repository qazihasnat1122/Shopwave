import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../utils/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/search'); break;
      case 2: context.go('/cart'); break;
      case 3: context.go('/orders'); break;
      case 4: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start cart stream when user is authenticated
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final cartBloc = context.read<CartBloc>();
      if (cartBloc.state is CartInitial) {
        cartBloc.add(CartStarted(userId: authState.user.uid));
      }
    }

    // GoRouter handles route state — return Scaffold directly (no RouterNotifierBloc needed)
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: _locationToIndex(
          GoRouterState.of(context).matchedLocation,
        ),
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final cartCount = cartState is CartLoaded ? cartState.itemCount : 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface1,
            border:
                Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: currentIndex == 0,
                      onTap: () => onTap(0)),
                  _NavItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      isActive: currentIndex == 1,
                      onTap: () => onTap(1)),
                  _NavItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Cart',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                    badge: cartCount > 0 ? cartCount.toString() : null,
                  ),
                  _NavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Orders',
                      isActive: currentIndex == 3,
                      onTap: () => onTap(3)),
                  _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      isActive: currentIndex == 4,
                      onTap: () => onTap(4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badges.Badge(
              showBadge: badge != null,
              badgeContent: Text(badge ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
              badgeStyle:
                  const badges.BadgeStyle(badgeColor: AppTheme.accent),
              child: Icon(icon,
                  color:
                      isActive ? AppTheme.primary : AppTheme.textTertiary,
                  size: 22),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.primary : AppTheme.textTertiary,
                )),
          ],
        ),
      ),
    );
  }
}
