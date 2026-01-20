// import 'package:fairshare/core/theme/app_theme.dart';
// import 'package:fairshare/screens/signin_screen.dart';
// import 'package:fairshare/services/supabase_service.dart';
// import 'package:flutter/material.dart';

// class ResetPasswordForm extends StatefulWidget {
//   const ResetPasswordForm({super.key});

//   @override
//   State<ResetPasswordForm> createState() => _ResetPasswordFormState();
// }

// class _ResetPasswordFormState extends State<ResetPasswordForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _passwordController = TextEditingController();
//   final _confirmController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _passwordController.dispose();
//     _confirmController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       await SupabaseService().updatePassword(_passwordController.text);

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Password updated — please sign in')),
//       );

//       // Navigate to login
//       Navigator.of(
//         context,
//       ).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen()));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update password: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Reset password')),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 24),
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     labelText: 'New password',
//                     hintText: 'Enter a secure password',
//                   ),
//                   validator: (v) {
//                     if (v == null || v.isEmpty) return 'Enter a password';
//                     if (v.length < 6) return 'Must be at least 6 characters';
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _confirmController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     labelText: 'Confirm password',
//                     hintText: 'Re-enter your password',
//                   ),
//                   validator: (v) {
//                     if (v == null || v.isEmpty) return 'Confirm your password';
//                     if (v != _passwordController.text)
//                       return 'Passwords do not match';
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submit,
//                     child: _isLoading
//                         ? const CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               Colors.white,
//                             ),
//                           )
//                         : const Text('Set new password'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.teal600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
