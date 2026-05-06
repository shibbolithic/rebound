import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/models.dart';

class AuthController {
  final SupabaseClient _client = SupabaseConfig.client;

  // =====================================================
  // SIGN UP
  // =====================================================
  Future<User?> signUp({
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
      'id': user.id,
      'email': email,
      'display_name': name,
      'role': role,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Only athletes get profile immediately
    if (role == 'athlete') {
      await _client.from('athlete_profiles').insert({
        'user_id': user.id,
        'experience_years': 0,
        'avg_points_per_game': 0,
        'avg_rebounds_per_game': 0,
        'avg_assists_per_game': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    // 🚨 Coaches DO NOT get coach_profiles here
    // That happens ONLY after admin approval

    return user;
  }

  // =====================================================
  // SIGN IN
  // =====================================================
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response.user;
  }

  // =====================================================
  // GET CURRENT USER FULL DATA
  // =====================================================
  Future<UsersTable> getCurrentUserData() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user');
    }

    final res = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return UsersTable.fromMap(res);
  }

  // =====================================================
  // GET USER ROLE (lightweight helper)
  // =====================================================
  Future<String> getUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user');
    }

    final res = await _client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    return res['role'] as String;
  }

  // =====================================================
  // GET COACH APPROVAL STATUS
  // =====================================================
  Future<String?> getCoachApprovalStatus(String userId) async {

    final res = await _client
        .from('coach_approval')
        .select('status')
        .eq('user_id', userId)
        .limit(1);

      if (res.isEmpty) return null;

  return res.first['status'] as String?;

  }

  // =====================================================
  // LOGOUT
  // =====================================================
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // =====================================================
  // CURRENT USER GETTER
  // =====================================================
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
