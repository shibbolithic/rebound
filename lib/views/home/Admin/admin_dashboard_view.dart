import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/models.dart';

const Color kBg = Color(0xFF0F0F10);
const Color kCard = Color(0xFF1C1C1E);
const Color kPrimaryOrange = Color(0xFFFF6A2A);
const Color kTextPrimary = Colors.white;
const Color kTextSecondary = Color(0xFF9A9A9E);
const BorderRadius kRadiusXL =
    BorderRadius.all(Radius.circular(22));

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() =>
      _AdminDashboardViewState();
}

class _AdminDashboardViewState
    extends State<AdminDashboardView> {

  final supabase = Supabase.instance.client;

  int athleteCount = 0;
  List<dynamic> pending = [];
  List<dynamic> approved = [];
  List<dynamic> rejected = [];

  bool showAllPending = false;
  int selectedSegment = 0; // 0 = approved, 1 = rejected

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    // 👥 Count athletes
    final athletes = await supabase
        .from('users')
        .select()
        .eq('role', 'athlete');

    athleteCount = athletes.length;

    // ⏳ Pending approvals
    pending = await supabase
        .from('coach_approval')
        .select('*, users(display_name,email)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    // ✅ Approved
    approved = await supabase
        .from('coach_approval')
        .select('*, users(display_name,email)')
        .eq('status', 'approved');

    // ❌ Rejected
    rejected = await supabase
        .from('coach_approval')
        .select('*, users(display_name,email)')
        .eq('status', 'rejected');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text(
          "Admin",
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: kPrimaryOrange,
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ===============================
            // 1️⃣ ATHLETE COUNT
            // ===============================

            _statCard(
              title: "Total Athletes",
              value: athleteCount.toString(),
            ),

            const SizedBox(height: 28),

            // ===============================
            // 2️⃣ RECENT PENDING
            // ===============================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Pending Approvals",
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAllPending = !showAllPending;
                    });
                  },
                  child: Text(
                    showAllPending
                        ? "Show Less"
                        : "Show All",
                    style: const TextStyle(
                        color: kPrimaryOrange),
                  ),
                )
              ],
            ),

            const SizedBox(height: 12),

            ..._buildPendingList(),

            const SizedBox(height: 30),

            // ===============================
            // 3️⃣ SEGMENTED CONTROL
            // ===============================

            Container(
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: kRadiusXL,
              ),
              child: Row(
                children: [
                  _segmentButton("Approved", 0),
                  _segmentButton("Rejected", 1),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ..._buildSegmentList(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS
  // ==========================================

  Widget _statCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: kRadiusXL,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: kTextSecondary)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryOrange)),
        ],
      ),
    );
  }

  List<Widget> _buildPendingList() {
    final list = showAllPending
        ? pending
        : pending.take(3).toList();

    return list
        .map((coach) =>
            _coachCard(coach, isPending: true))
        .toList();
  }

  List<Widget> _buildSegmentList() {
    final list =
        selectedSegment == 0 ? approved : rejected;

    return list
        .map((coach) =>
            _coachCard(coach, isPending: false))
        .toList();
  }

  Widget _segmentButton(String title, int index) {
    final isSelected = selectedSegment == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSegment = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryOrange
                : Colors.transparent,
            borderRadius: kRadiusXL,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : kTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coachCard(dynamic coach,
      {required bool isPending}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/coach-detail',
          arguments: coach,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: kRadiusXL,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              coach['users']['display_name'] ??
                  "",
              style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              coach['users']['email'] ?? "",
              style: const TextStyle(
                  color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}