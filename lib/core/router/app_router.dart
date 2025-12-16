import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/student/presentation/presentation.dart';
import '../../features/admin/presentation/presentation.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';

      // Not logged in -> redirect to login (except register page)
      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute) {
        return '/login';
      }

      // Logged in and on login/register page -> redirect based on role
      if (isLoggedIn && (isLoginRoute || isRegisterRoute)) {
        if (authState.isAdmin) {
          return '/admin';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      // Login Route
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Register Route
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Student Shell Route with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/shelf',
            name: 'shelf',
            builder: (context, state) => const MyShelfScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Book Detail Route (outside shell for full screen)
      GoRoute(
        path: '/detail/:id',
        name: 'bookDetail',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return BookDetailScreen(bookId: bookId);
        },
      ),

      // E-Reader Route
      GoRoute(
        path: '/reader/:id',
        name: 'reader',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return ReaderScreen(bookId: bookId);
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'scan',
            name: 'adminScan',
            builder: (context, state) {
              final prefillId = state.extra as String?;
              return ScannerScreen(prefillBookingId: prefillId);
            },
          ),
          GoRoute(
            path: 'add-book',
            name: 'addBook',
            builder: (context, state) => const AddBookScreen(),
          ),
          GoRoute(
            path: 'stats',
            name: 'adminStats',
            builder: (context, state) => const AdminStatsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});
