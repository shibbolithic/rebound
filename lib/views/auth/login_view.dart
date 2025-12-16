// import 'package:flutter/material.dart';
// import '../../controllers/auth_controller.dart';

// class LoginView extends StatelessWidget {
//   LoginView({super.key});

//   final AuthController _authController = AuthController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const Spacer(),

//               /// App Title
//               const Text(
//                 'Athlenix',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),

//               const SizedBox(height: 40),

//               /// Email Field (UI only for now)
//               _inputField(
//                 icon: Icons.email_outlined,
//                 hint: 'Enter your Email',
//                 obscure: false,
//               ),

//               const SizedBox(height: 16),

//               /// Password Field (UI only)
//               _inputField(
//                 icon: Icons.lock_outline,
//                 hint: 'Password',
//                 obscure: true,
//               ),

//               const SizedBox(height: 8),

//               /// Forgot password
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: Text(
//                   'Forgot Password ?',
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               /// Login Button (visual)
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: () {},
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFFFB49D),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: const Text(
//                     'Login',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               /// Sign up text
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const [
//                   Text(
//                     "Don’t have an account? ",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                   Text(
//                     "Sign up",
//                     style: TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 30),

//               /// Continue with accounts
//               const Text(
//                 'Continue With Accounts',
//                 style: TextStyle(color: Colors.grey),
//               ),

//               const SizedBox(height: 16),

//               /// Google Button
//               GestureDetector(
//                 onTap: () async {
//                   await _authController.signInWithGoogle();
//                 },
//                 child: Container(
//                   height: 50,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Center(
//                     child: Image(
//                       image: AssetImage('assets/google.png'),
//                       height: 22,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Reusable input field widget
//   Widget _inputField({
//     required IconData icon,
//     required String hint,
//     required bool obscure,
//   }) {
//     return Container(
//       height: 50,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.grey),
//           const SizedBox(width: 12),
//           Expanded(
//             child: TextField(
//               obscureText: obscure,
//               decoration: InputDecoration(
//                 border: InputBorder.none,
//                 hintText: hint,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
