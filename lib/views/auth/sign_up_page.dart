// import 'package:flutter/material.dart';
// import '../../controllers/auth_controller.dart';
// import 'otp_view.dart';

// class SignUpPage extends StatefulWidget {
//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   final emailController = TextEditingController();
//   String selectedRole = 'athlete';
//   final authController = AuthController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           TextField(
//             controller: emailController,
//             decoration: InputDecoration(labelText: "Email"),
//           ),

//           DropdownButton<String>(
//             value: selectedRole,
//             items: ['athlete', 'coach']
//                 .map((role) => DropdownMenuItem(
//                       value: role,
//                       child: Text(role),
//                     ))
//                 .toList(),
//             onChanged: (val) => setState(() => selectedRole = val!),
//           ),

//           ElevatedButton(
//             onPressed: () async {
//               await authController.requestOtp(emailController.text);

//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => OtpPage(
//                     email: emailController.text,
//                     role: selectedRole,
//                     isSignup: true,
//                   ),
//                 ),
//               );
//             },
//             child: Text("Continue"),
//           ),
//         ],
//       ),
//     );
//   }
// }
