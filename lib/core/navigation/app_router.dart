import 'package:fairshare/screens/home/home_screen.dart';
import 'package:fairshare/screens/auth/signin_screen.dart';
import 'package:fairshare/screens/auth/signup_screen.dart';
import 'package:fairshare/screens/dashboard/main_screen.dart';
import 'package:fairshare/services/auth_callback_handler.dart';
import 'package:flutter/material.dart';
import 'package:fairshare/screens/splash/splash_screen.dart';

/// App Route Names - Define all routes here
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main'; // Main screen with bottom nav
  static const String home = '/home';
  static const String authCallback = '/auth/callback';
  // Alternative auth callback routes for deep linking
  static const String authCallbackAlt = '/auth-callback';
  static const String authCallbackNoSlash = 'auth-callback';
  static const String groups = '/groups';
  static const String addExpense = '/add-expense';
  static const String activity = '/activity';
  static const String profile = '/profile';
}

/// App Router - Centralized routing configuration
class AppRouter {
  /// Generate routes for named navigation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint('🗺️ Generating route for: ${settings.name}');

    // CRITICAL FIX: Check if this is the root route with a 'code' query parameter
    // This handles deep links like: /?code=85f760ff-ceb4-4219-a18c-9f77ed6de195
    if (settings.name == '/' || settings.name == '') {
      // Check if there's a URI with query parameters
      final uri = Uri.tryParse(settings.name ?? '/');
      if (uri != null && uri.queryParameters.containsKey('code')) {
        debugPrint(
          '🔗 Root route with code parameter detected - treating as auth callback',
        );
        debugPrint('   Code: ${uri.queryParameters['code']}');
        return MaterialPageRoute(
          builder: (_) => const AuthCallbackHandler(),
          settings: settings,
        );
      }
    }

    switch (settings.name) {
      case AppRoutes.splash:
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const SignInScreen(),
          settings: settings,
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings: settings,
        );

      case AppRoutes.main:
        // Main screen with bottom navigation
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );

      case AppRoutes.home:
        // Keep this for direct access if needed
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      // Handle all auth callback variations for deep linking
      case AppRoutes.authCallback:
      case AppRoutes.authCallbackAlt:
      case AppRoutes.authCallbackNoSlash:
      case '/auth-callback': // With slash
      case 'auth-callback': // Without slash
        debugPrint('✅ Auth callback route matched: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => const AuthCallbackHandler(),
          settings: settings,
        );

      // Add more routes as needed
      default:
        debugPrint('⚠️ Unknown route: ${settings.name}');

        // IMPROVED: Check for query parameters in any route
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri != null && uri.queryParameters.containsKey('code')) {
          debugPrint(
            '🔗 Unknown route with code parameter - treating as auth callback',
          );
          return MaterialPageRoute(
            builder: (_) => const AuthCallbackHandler(),
            settings: settings,
          );
        }

        // Check if route contains 'auth', treat as auth callback
        if (settings.name?.toLowerCase().contains('auth') ?? false) {
          debugPrint('🔗 Treating as auth callback due to "auth" in route');
          return MaterialPageRoute(
            builder: (_) => const AuthCallbackHandler(),
            settings: settings,
          );
        }

        // Otherwise, redirect to splash screen
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }

  /// Navigate to a named route
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigate and remove all previous routes
  static Future<dynamic> navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Replace current route
  static Future<dynamic> navigateReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
