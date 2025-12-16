
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthController {
  final SupabaseClient _client = SupabaseConfig.client;

  /// SIGN UP
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Signup failed');
    }

    // Insert into users table
    await _client.from('users').insert({
      'id': user.id, // FK → auth.users.id
      'email': email,
      'display_name': name,
      'role': role,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Role-based profile
    if (role == 'athlete') {
      await _client.from('athlete_profiles').insert({
        'user_id': user.id,
      });
    } else {
      await _client.from('coach_profiles').insert({
        'user_id': user.id,
      });
    }
  }

  /// SIGN IN
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// LOGOUT
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}

// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../core/supabase_client.dart';

// class AuthController {
//   final _client = SupabaseConfig.client;

//   // STEP 1: SIGN UP
//   Future<void> signUp({
//     required String name,
//     required String email,
//     required String password,
//     required String role,
//   }) async {
//     final res = await _client.auth.signUp(
//       email: email,
//       password: password,
//       data: {'name': name},
//     );

//     final user = res.user;
//     if (user == null) throw Exception("Signup failed");

//     // Insert into users table
//     await _client.from('users').insert({
//       'id': user.id,
//       'email': email,
//       'display_name': name,
//       'role': role,
//       'created_at': DateTime.now().toIso8601String(),
//       'is_active': true,
//     });

//     // Create role-specific profile
//     if (role == 'athlete') {
//       await _client.from('athlete_profiles').insert({
//         'user_id': user.id,
//       });
//     } else {
//       await _client.from('coach_profiles').insert({
//         'user_id': user.id,
//       });
//     }
//   }

  // STEP 2: VERIFY OTP
  // Future<void> verifyOtp({
  //   required String email,
  //   required String otp,
  // }) async {
  //   await _client.auth.verifyOTP(
  //     email: email,
  //     token: otp,
  //     type: OtpType.signup,
  //   );
  // }


  // Future<void> resendOtp(String email) async {
  //   await _client.auth.resend(
  //     type: OtpType.signup,
  //     email: email,
  //   );
  // }
// }
