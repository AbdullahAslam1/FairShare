import 'package:flutter/material.dart';

/// Global Navigation Service
/// Allows navigation without BuildContext
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current context
  static BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to route by name
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and remove all previous routes
  static Future<dynamic> navigateAndRemoveUntil(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Replace current route
  static Future<dynamic> navigateReplace(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack() {
    return navigatorKey.currentState!.pop();
  }

  /// Check if can go back
  static bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }
}
