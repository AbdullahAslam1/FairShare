import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fairshare/core/navigation/app_router.dart';
import 'package:fairshare/core/navigation/navigation_service.dart';
import 'package:fairshare/core/theme/app_theme.dart';

/// This widget handles the auth callback after email verification
/// It will automatically redirect users to the appropriate screen
class AuthCallbackHandler extends ConsumerStatefulWidget {
  const AuthCallbackHandler({super.key});

  @override
  ConsumerState<AuthCallbackHandler> createState() =>
      _AuthCallbackHandlerState();
}

class _AuthCallbackHandlerState extends ConsumerState<AuthCallbackHandler> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      debugPrint('🔄 Starting auth callback handler...');

      // CRITICAL FIX: Refresh the session to get the latest user data
      await Supabase.instance.client.auth.refreshSession();

      // Get the current session after refresh
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null && session.user != null) {
        final user = session.user!;

        debugPrint('✅ Auth callback - User: ${user.email}');
        debugPrint('📧 Email confirmed at: ${user.emailConfirmedAt}');

        // IMPORTANT: After clicking the verification link, the email should now be confirmed
        if (user.emailConfirmedAt != null) {
          debugPrint(
            '✅ Email verified successfully, navigating to main screen',
          );

          if (mounted) {
            NavigationService.navigateAndRemoveUntil(AppRoutes.main);
          }
        } else {
          // This should rarely happen now with the session refresh
          debugPrint('⚠️ Email not verified yet after refresh');
          setState(() {
            _isProcessing = false;
            _errorMessage =
                'Email verification is still pending. Please try signing in again or check your email for the verification link.';
          });
        }
      } else {
        // No session found
        debugPrint('❌ No session found, redirecting to sign in');

        if (mounted) {
          NavigationService.navigateAndRemoveUntil(AppRoutes.login);
        }
      }
    } catch (e) {
      debugPrint('❌ Auth callback error: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'An error occurred during verification. Please try signing in again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal600, AppColors.purple600],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated loading indicator
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verifying your email...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait a moment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error screen
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.teal600, AppColors.purple600],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error Title
                  const Text(
                    'Verification Issue',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Message
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _errorMessage ?? 'Something went wrong',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Column(
                    children: [
                      // Retry Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isProcessing = true;
                              _errorMessage = null;
                            });
                            _handleCallback();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.teal600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.refresh_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Back to Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            NavigationService.navigateAndRemoveUntil(
                              AppRoutes.login,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Back to Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
