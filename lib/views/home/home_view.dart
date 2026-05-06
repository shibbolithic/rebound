import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // REQUIRED for blur
import 'home_tab_view.dart'; // athlete
import 'coach/coach_home_tab_view.dart';
import '../profile/profile_view.dart';
import '../create/create_modal.dart';
import '../home/coach/coach_profile_tab_view.dart';

/* ======================
   THEME TOKENS
   ====================== */

const kBlack = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kOrange = Color(0xFFFF6B35);
const kGrey = Color(0xFF8E8E93);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  String? role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    setState(() {
      role = res['role'];
    });
  }

  void _openCreateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CreateModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const Scaffold(
        backgroundColor: kBlack,
        body: Center(
          child: CircularProgressIndicator(color: kOrange),
        ),
      );
    }

    final pages = [
      role == 'coach'
          ? const CoachHomeTabView()
          : const HomeTabView(),
      role == 'coach'
          ? const CoachProfileView()
          : const AthleteProfileView(),
    ];

    return Scaffold(
      backgroundColor: kBlack,
      body: pages[_currentIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateModal,
        backgroundColor: kOrange,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      decoration: BoxDecoration(
        color: kCard.withOpacity(1.0), // translucent dark glass
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _currentIndex.clamp(0, pages.length - 1),
        selectedItemColor: kOrange,
        unselectedItemColor: kGrey,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    ),
  ),
),
    );
  }
}
