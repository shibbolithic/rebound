import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/supabase_client.dart';
import 'controllers/tab_controller.dart';

import 'views/auth/register_view.dart';
import 'views/auth/login_view.dart';
import 'views/home/home_view.dart';

import 'views/auth/coach_approval_form_view.dart';
import 'views/auth/coach_pending_view.dart';

import 'views/home/Admin/admin_dashboard_view.dart';
import 'views/home/Admin/coach_detail_view.dart'; // ✅ ADD THIS

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const AthlinixApp());
}

class AthlinixApp extends StatelessWidget {
  const AthlinixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTabController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'rebound',

        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFFFF6B35),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),

        initialRoute: '/',

        routes: {
          '/': (context) => const RegisterView(),
          '/login': (context) => const LoginView(),
          '/home': (context) => const HomeView(),

          '/coach-approval-form': (_) =>
              const CoachApprovalFormView(),
          '/coach-pending': (_) =>
              const CoachPendingView(),

          '/admin-dashboard': (_) =>
              const AdminDashboardView(),
        },

        // ✅ HANDLE ROUTES WITH ARGUMENTS
        onGenerateRoute: (settings) {
          if (settings.name == '/coach-detail') {
            final coachData =
                settings.arguments as Map<String, dynamic>;

            return MaterialPageRoute(
              builder: (context) =>
                  CoachDetailView(coach: coachData),
            );
          }

          return null;
        },
      ),
    );
  }
}