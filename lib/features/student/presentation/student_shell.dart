import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../auth/auth_provider.dart';
import '../../favorite/favorite_provider.dart';

class StudentShell extends ConsumerStatefulWidget {
  final Widget child;

  const StudentShell({super.key, required this.child});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadFavorites());
  }

  Future<void> _loadFavorites() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(favoriteProvider.notifier).loadFavorites(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  icon: LucideIcons.home,
                  label: 'Home',
                  path: '/home',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.search,
                  label: 'Search',
                  path: '/search',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.bookMarked,
                  label: 'My Shelf',
                  path: '/shelf',
                ),
                _buildNavItem(
                  context,
                  icon: LucideIcons.user,
                  label: 'Profile',
                  path: '/profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
  }) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isSelected = currentPath == path;

    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
