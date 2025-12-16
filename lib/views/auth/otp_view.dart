// import 'package:flutter/material.dart';
// import '../../controllers/auth_controller.dart';

// class OtpView extends StatefulWidget {
//   const OtpView({super.key});

//   @override
//   State<OtpView> createState() => _OtpViewState();
// }

// class _OtpViewState extends State<OtpView> {
//   final _auth = AuthController();
//   final otpCtrl = TextEditingController();

//   void verify(String email) async {
//     await _auth.verifyOtp(email: email, otp: otpCtrl.text);
//     Navigator.pushReplacementNamed(context, '/home');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final email = ModalRoute.of(context)!.settings.arguments as String;

//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             const SizedBox(height: 80),
//             const Text("Verify Email", style: TextStyle(fontSize: 28)),
//             Text(email),
//             const SizedBox(height: 24),

//             TextField(
//               controller: otpCtrl,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(hintText: "Enter OTP"),
//             ),

//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () => verify(email),
//               child: const Text("Verify"),
//             ),
//             TextButton(
//               onPressed: () => _auth.resendOtp(email),
//               child: const Text("Send Again"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// // import 'package:flutter/material.dart';
// // import '../../controllers/auth_controller.dart';
// // import '../home/home_view.dart';


// // class OtpPage extends StatelessWidget {
// //   final String email;
// //   final String? role;
// //   final bool isSignup;

// //   final otpController = TextEditingController();
// //   final authController = AuthController();

// //   OtpPage({
// //     required this.email,
// //     this.role,
// //     required this.isSignup,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Column(
// //         children: [
// //           TextField(controller: otpController),
// //           ElevatedButton(
// //             onPressed: () async {
// //               await authController.verifyOtp(
// //                 email: email,
// //                 otp: otpController.text,
// //               );

// //               if (isSignup) {
// //                 final exists = await authController.doesAppUserExist();

// //                 if (!exists) {
// //                   await authController.onboardUser(role: role!);
// //                 }
// //               }

// //               Navigator.pushAndRemoveUntil(
// //                 context,
// //                 MaterialPageRoute(builder: (_) => HomeView()),
// //                 (_) => false,
// //               );
// //             },
// //             child: Text("Verify & Continue"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
