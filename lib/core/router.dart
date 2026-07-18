import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/firebase_services.dart';
import '../data/models/models.dart';
import '../presentation/auth/screens/login_screen.dart';
import '../presentation/auth/screens/register_screen.dart';
import '../presentation/auth/screens/forgot_password_screen.dart';
import '../presentation/auth/screens/onboarding_screen.dart';
import '../presentation/auth/screens/verify_email_screen.dart';
import '../presentation/home/screens/home_screen.dart';
import '../presentation/clubs/screens/clubs_screen.dart';
import '../presentation/clubs/screens/club_detail_screen.dart';
import '../presentation/events/screens/events_screen.dart';
import '../presentation/events/screens/event_detail_screen.dart';
import '../presentation/team_up/screens/team_up_screen.dart';
import '../presentation/team_up/screens/create_post_screen.dart';
import '../presentation/profile/screens/profile_screen.dart';
import '../presentation/profile/screens/edit_profile_screen.dart';
import '../presentation/profile/screens/help_support_screen.dart';
import '../presentation/profile/screens/notification_settings_screen.dart';
import '../presentation/profile/screens/followed_clubs_screen.dart';
import '../presentation/profile/screens/registered_events_screen.dart';
import '../presentation/admin/screens/admin_dashboard_screen.dart';
import '../presentation/admin/screens/super_admin_screen.dart';
import '../shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) async {
      final firebaseUser = authState.valueOrNull;
      final isLoggedIn = firebaseUser != null;
      final isVerified = firebaseUser?.emailVerified ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isVerifyRoute = state.matchedLocation == '/auth/verify-email';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthRoute && !isOnboarding) return '/auth/login';

    
      if (isLoggedIn && !isVerified && !isVerifyRoute && !isAuthRoute) {
        return '/auth/verify-email';
      }

      if (isLoggedIn && isVerified && isVerifyRoute) return '/home';

      if (isLoggedIn && isVerified && isAuthRoute) {
        final prefs = await SharedPreferences.getInstance();
        final done = prefs.getBool('onboarding_done') ?? false;
        if (!done) return '/onboarding';
        return '/home';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/auth/verify-email', builder: (_, __) => const VerifyEmailScreen()),

      // Onboarding
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/clubs', builder: (_, __) => const ClubsScreen()),
          GoRoute(path: '/events', builder: (_, __) => const EventsScreen()),
          GoRoute(path: '/team-up', builder: (_, __) => const TeamUpScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Club detail
      GoRoute(
        path: '/clubs/:id',
        builder: (_, state) => ClubDetailScreen(clubId: state.pathParameters['id']!),
      ),

      // Event detail
      GoRoute(
        path: '/events/:id',
        builder: (_, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
      ),

      // Team Up create
      GoRoute(path: '/team-up/create', builder: (_, __) => const CreatePostScreen()),

      // Team Up edit
      GoRoute(
        path: '/team-up/edit',
        builder: (_, state) => CreatePostScreen(editPost: state.extra as TeamUpPost?),
      ),

      // Admin
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/super-admin', builder: (_, __) => const SuperAdminScreen()),

      // Profile sub-screens
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/help-support', builder: (_, __) => const HelpSupportScreen()),
      GoRoute(path: '/profile/followed-clubs', builder: (_, __) => const FollowedClubsScreen()),
      GoRoute(path: '/profile/registered-events', builder: (_, __) => const RegisteredEventsScreen()),
      GoRoute(path: '/profile/notifications', builder: (_, __) => const NotificationSettingsScreenWrapper()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
});