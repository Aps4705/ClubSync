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

/// Quick cross-fade + gentle scale — used for the bottom-nav tabs (/home,
/// /clubs, /events, /team-up, /profile). Lateral switches, not "pushes",
/// so no slide — the scale-in is what sells it as a transition rather than
/// a flat cut.
CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      final scale = Tween<double>(begin: 0.97, end: 1.0).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

/// Shared-axis push transition — used for anything you "push into" (detail
/// screens, forms, auth flow, admin). The incoming page slides in from the
/// right while fading up; the page being covered slides slightly left and
/// dims — both sides move, which is what actually reads as a "transition"
/// instead of a fade-in-place.
CustomTransitionPage _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final incoming = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      final outgoing = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

      final slideIn = Tween<Offset>(begin: const Offset(0.18, 0), end: Offset.zero).animate(incoming);
      final fadeIn = Tween<double>(begin: 0, end: 1).animate(incoming);
      final scaleIn = Tween<double>(begin: 0.96, end: 1.0).animate(incoming);

      final slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.06, 0)).animate(outgoing);
      final fadeOut = Tween<double>(begin: 1, end: 0.35).animate(outgoing);

      return SlideTransition(
        position: slideOut,
        child: FadeTransition(
          opacity: fadeOut,
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: ScaleTransition(scale: scaleIn, child: child),
            ),
          ),
        ),
      );
    },
  );
}

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

      if (isLoggedIn && isVerified && !isOnboarding) {
        final prefs = await SharedPreferences.getInstance();
        final done = prefs.getBool('onboarding_done') ?? false;
        if (!done) return '/onboarding';
        if (isAuthRoute) return '/home';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/auth/login', pageBuilder: (_, state) => _slidePage(const LoginScreen(), state)),
      GoRoute(path: '/auth/register', pageBuilder: (_, state) => _slidePage(const RegisterScreen(), state)),
      GoRoute(path: '/auth/forgot-password', pageBuilder: (_, state) => _slidePage(const ForgotPasswordScreen(), state)),
      GoRoute(path: '/auth/verify-email', pageBuilder: (_, state) => _slidePage(const VerifyEmailScreen(), state)),

      // Onboarding
      GoRoute(path: '/onboarding', pageBuilder: (_, state) => _slidePage(const OnboardingScreen(), state)),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (_, state) => _fadePage(const HomeScreen(), state)),
          GoRoute(path: '/clubs', pageBuilder: (_, state) => _fadePage(const ClubsScreen(), state)),
          GoRoute(path: '/events', pageBuilder: (_, state) => _fadePage(const EventsScreen(), state)),
          GoRoute(path: '/team-up', pageBuilder: (_, state) => _fadePage(const TeamUpScreen(), state)),
          GoRoute(path: '/profile', pageBuilder: (_, state) => _fadePage(const ProfileScreen(), state)),
        ],
      ),

      // Club detail
      GoRoute(
        path: '/clubs/:id',
        pageBuilder: (_, state) => _slidePage(
          ClubDetailScreen(clubId: state.pathParameters['id']!),
          state,
        ),
      ),

      // Event detail
      GoRoute(
        path: '/events/:id',
        pageBuilder: (_, state) => _slidePage(
          EventDetailScreen(eventId: state.pathParameters['id']!),
          state,
        ),
      ),

      // Team Up create
      GoRoute(path: '/team-up/create', pageBuilder: (_, state) => _slidePage(const CreatePostScreen(), state)),

      // Team Up edit
      GoRoute(
        path: '/team-up/edit',
        pageBuilder: (_, state) => _slidePage(
          CreatePostScreen(editPost: state.extra as TeamUpPost?),
          state,
        ),
      ),

      // Admin
      GoRoute(path: '/admin', pageBuilder: (_, state) => _slidePage(const AdminDashboardScreen(), state)),
      GoRoute(path: '/super-admin', pageBuilder: (_, state) => _slidePage(const SuperAdminScreen(), state)),

      // Profile sub-screens
      GoRoute(path: '/profile/edit', pageBuilder: (_, state) => _slidePage(const EditProfileScreen(), state)),
      GoRoute(path: '/help-support', pageBuilder: (_, state) => _slidePage(const HelpSupportScreen(), state)),
      GoRoute(path: '/profile/followed-clubs', pageBuilder: (_, state) => _slidePage(const FollowedClubsScreen(), state)),
      GoRoute(path: '/profile/registered-events', pageBuilder: (_, state) => _slidePage(const RegisteredEventsScreen(), state)),
      GoRoute(path: '/profile/notifications', pageBuilder: (_, state) => _slidePage(const NotificationSettingsScreenWrapper(), state)),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
});