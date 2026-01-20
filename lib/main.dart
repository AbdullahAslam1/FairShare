import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/core/navigation/app_router.dart';
import 'package:fairshare/core/navigation/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://leyjvnpaqbwqzfruqntt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxleWp2bnBhcWJ3cXpmcnVxbnR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzOTIwMjEsImV4cCI6MjA3OTk2ODAyMX0.sxYqlOLt0pFiJv9_t2QV83rCjZV7ZEEZFQRIvUowJo8',
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ADDED: Flag to prevent double navigation
  bool _initialNavigationDone = false;

  @override
  void initState() {
    super.initState();
    // Setup auth listener AFTER the widget tree is built
    _setupAuthListener();
  }

  /// Setup authentication state listener
  /// This now runs AFTER the app is initialized, so navigation works properly
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint('🔐 Auth event: $event');

      // Only navigate if we have a valid context and navigator
      if (!mounted) return;

      // Handle different auth events
      switch (event) {
        case AuthChangeEvent.signedIn:
          debugPrint('✅ User signed in: ${session?.user.email}');
          debugPrint(
            '📧 Email verified: ${session?.user.emailConfirmedAt != null}',
          );

          // CRITICAL FIX: Only navigate if email is verified AND not already navigated
          // This prevents conflict with SplashScreen navigation
          if (session?.user.emailConfirmedAt != null &&
              !_initialNavigationDone) {
            _initialNavigationDone = true; // PREVENT DOUBLE NAVIGATION
            debugPrint('🚀 Auth listener: Navigating to main screen');

            // Use a short delay to ensure the widget tree is ready
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted &&
                  NavigationService.navigatorKey.currentState != null) {
                NavigationService.navigateAndRemoveUntil(AppRoutes.main);
              }
            });
          } else if (session?.user.emailConfirmedAt == null) {
            debugPrint('⚠️ Email not verified yet, staying on current screen');
          } else {
            debugPrint('⚠️ Navigation already done, skipping');
          }
          break;

        case AuthChangeEvent.signedOut:
          debugPrint('❌ User signed out');
          _initialNavigationDone = false; // RESET FLAG

          // Navigate to login screen
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted &&
                NavigationService.navigatorKey.currentState != null) {
              NavigationService.navigateAndRemoveUntil(AppRoutes.login);
            }
          });
          break;

        case AuthChangeEvent.tokenRefreshed:
          debugPrint('🔄 Token refreshed');
          break;

        case AuthChangeEvent.userUpdated:
          debugPrint('👤 User updated');
          break;

        case AuthChangeEvent.passwordRecovery:
          debugPrint('🔑 Password recovery');
          break;

        default:
          debugPrint('ℹ️ Other auth event: $event');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FairShare',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Navigation Configuration
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,

      // CRITICAL: Handle deep links that don't match any route
      onUnknownRoute: (settings) {
        debugPrint('⚠️ Unknown route: ${settings.name}');

        // Check if this is an auth callback route
        if (settings.name?.toLowerCase().contains('auth') ?? false) {
          debugPrint('🔗 Auth callback detected via unknown route');
          return MaterialPageRoute(
            builder: (_) => const _DeepLinkHandler(),
            settings: settings,
          );
        }

        // Default to splash screen for unknown routes
        return AppRouter.generateRoute(RouteSettings(name: AppRoutes.splash));
      },
    );
  }
}

/// Temporary handler for deep links that processes auth callback
class _DeepLinkHandler extends StatefulWidget {
  const _DeepLinkHandler();

  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    _handleDeepLink();
  }

  Future<void> _handleDeepLink() async {
    debugPrint('🔗 Processing deep link...');

    // Add delay to let Supabase process the callback
    await Future.delayed(const Duration(milliseconds: 500));

    // Refresh session to get latest user data
    try {
      await Supabase.instance.client.auth.refreshSession();
      debugPrint('✅ Session refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing session: $e');
    }

    // Small delay after refresh
    await Future.delayed(const Duration(milliseconds: 300));

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (mounted) {
      if (user != null && user.emailConfirmedAt != null) {
        debugPrint('✅ Email verified, navigating to main');
        NavigationService.navigateAndRemoveUntil(AppRoutes.main);
      } else {
        debugPrint('⚠️ User not verified, going to login');
        NavigationService.navigateAndRemoveUntil(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lightTheme.primaryColor, Colors.purple],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifying your email...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
