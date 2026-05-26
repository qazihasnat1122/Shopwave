import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../services/seeder_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _nameCtrl.text = auth.user.displayName;
      _phoneCtrl.text = auth.user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _pickAndUploadAvatar() async {
    // Capture state synchronously BEFORE any await
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    final ref = FirebaseStorage.instance
        .ref('avatars/${authState.user.uid}.jpg');
    await ref.putFile(File(file.path));
    await ref.getDownloadURL();

    // Update in Firestore via AuthRepository
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              TextButton(
                onPressed: () => setState(() => _editing = !_editing),
                child: Text(_editing ? 'Cancel' : 'Edit',
                  style: const TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // Avatar
              Stack(children: [
                GestureDetector(
                  onTap: _editing ? _pickAndUploadAvatar : null,
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: user.photoUrl != null
                        ? ClipOval(child: Image.network(user.photoUrl!, fit: BoxFit.cover))
                        : Center(child: Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                              color: Colors.white, fontFamily: 'Syne'),
                          )),
                  ),
                ),
                if (_editing)
                  Positioned(bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),

              Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
              Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),

              // Edit Fields
              if (_editing) ...[
                AppTextField(
                  controller: _nameCtrl, label: 'Full Name',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _phoneCtrl, label: 'Phone',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Save Changes', onPressed: () {
                  // Update profile
                  setState(() => _editing = false);
                }),
                const SizedBox(height: 24),
              ],

              // Menu items
              _MenuSection(
                title: 'Account',
                items: [
                  _MenuItem(Icons.location_on_outlined, 'Saved Addresses', () {}),
                  _MenuItem(Icons.credit_card_outlined, 'Payment Methods', () {}),
                  _MenuItem(Icons.notifications_outlined, 'Notifications', () {}),
                ],
              ),
              const SizedBox(height: 16),
              _MenuSection(
                title: 'Shopping',
                items: [
                  _MenuItem(Icons.favorite_border_rounded, 'Wishlist', () {}),
                  _MenuItem(Icons.receipt_long_outlined, 'Order History', () => context.go('/orders')),
                  _MenuItem(Icons.star_border_rounded, 'My Reviews', () {}),
                ],
              ),
              const SizedBox(height: 16),
              _MenuSection(
                title: 'Support',
                items: [
                  _MenuItem(Icons.help_outline_rounded, 'Help Center', () {}),
                  _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
                  _MenuItem(Icons.data_usage_rounded, 'Seed Test Data', () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seeding database...'))
                    );
                    await SeederService.seedDatabase();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Database seeded successfully!'))
                      );
                    }
                  }),
                  _MenuItem(Icons.info_outline_rounded, 'App Version', () {}, trailing: 'v1.0.0'),
                ],
              ),
              const SizedBox(height: 16),
              
              _MenuSection(
                title: 'Admin',
                items: [
                  _MenuItem(Icons.dashboard_customize_rounded, 'Admin Dashboard', () => context.push('/admin/products/add')),
                ],
              ),
              const SizedBox(height: 24),

              // Sign Out
              OutlinedButton.icon(
                onPressed: () => context.read<AuthBloc>().add(AuthSignOutRequested()),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.accent),
                label: const Text('Sign Out', style: TextStyle(color: AppTheme.accent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        );
      },
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0.08,
            textBaseline: TextBaseline.alphabetic,
          )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface2, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: List.generate(items.length, (i) => Column(children: [
              items[i],
              if (i < items.length - 1)
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1,
                  indent: 52, endIndent: 16),
            ])),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  const _MenuItem(this.icon, this.label, this.onTap, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailing != null
          ? Text(trailing!, style: Theme.of(context).textTheme.bodySmall)
          : const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
