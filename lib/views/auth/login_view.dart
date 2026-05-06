import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/auth_controller.dart';
import '../../models/models.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController _auth = AuthController();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;

 Future<void> login() async {
  setState(() => loading = true);

  try {
    // 1️⃣ Auth login
    final user = await _auth.signIn(
      email: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
    );

    if (user == null) {
      throw Exception("Authentication failed");
    }

    // 2️⃣ Fetch role
    final userData = await _auth.getCurrentUserData();
    final role = userData.role;

    if (role == 'athlete') {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
      return;
    }

    if (role == 'coach') {
      final approvalStatus =
          await _auth.getCoachApprovalStatus(user.id);

      if (approvalStatus == null) {
        Navigator.pushReplacementNamed(
            context, '/coach-approval-form');
        return;
      }

      if (approvalStatus == 'approved') {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      Navigator.pushReplacementNamed(
          context, '/coach-pending');
      return;
    }

  } on AuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  } catch (e) {
    print("LOGIN ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong'),
      ),
    );
  }

  setState(() => loading = false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Rebound',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
                hintText: 'Email',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Password',
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login'),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/'),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}