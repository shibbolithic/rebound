import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBg = Color(0xFF0F0F10);
const Color kCard = Color(0xFF1C1C1E);
const Color kPrimaryOrange = Color(0xFFFF6A2A);
const Color kTextPrimary = Colors.white;
const Color kTextSecondary = Color(0xFF9A9A9E);

const BorderRadius kRadiusXL = BorderRadius.all(
  Radius.circular(22),
);

class CoachDetailView extends StatefulWidget {
  final dynamic coach;

  const CoachDetailView({
    super.key,
    required this.coach,
  });

  @override
  State<CoachDetailView> createState() => _CoachDetailViewState();
}

class _CoachDetailViewState extends State<CoachDetailView> {
  final supabase = Supabase.instance.client;

  bool loading = false;

  /* -------------------- DATABASE ACTIONS -------------------- */

  Future<void> approveCoach() async {
    setState(() => loading = true);

    final coach = widget.coach;

    try {
      await supabase.from('coach_profiles').insert({
        'user_id': coach['user_id'],
        'years_experience': coach['years_experience'],
        'specialization': coach['specialisation'],
        'certifications': coach['certification_url'],
        'updated_at': DateTime.now().toIso8601String(),
      });

      await supabase.from('coach_approval').update({
        'status': 'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('user_id', coach['user_id']);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString());
    }

    setState(() => loading = false);
  }

  Future<void> rejectCoach() async {
    setState(() => loading = true);

    try {
      await supabase.from('coach_approval').update({
        'status': 'rejected',
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('user_id', widget.coach['user_id']);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString());
    }

    setState(() => loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /* -------------------- UI COMPONENTS -------------------- */

  Widget formRow(String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFF2C2C2E),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget groupedCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: kRadiusXL,
      ),
      child: Column(children: children),
    );
  }

  /* -------------------- BUILD -------------------- */

  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;
    final user = coach['users'];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          user['display_name'] ?? "",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
      ),
      body: Column(
        children: [

          /* ---------------- SCROLLABLE CONTENT ---------------- */

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  groupedCard([
                    formRow("Email", user['email'] ?? ""),
                    formRow("Specialisation", coach['specialisation'] ?? ""),
                    formRow("University", coach['university_name'] ?? ""),
                    formRow(
                      "Year of Passing",
                      coach['year_of_passing']?.toString() ?? "",
                    ),
                    formRow(
                      "University POC",
                      coach['university_poc_name'] ?? "",
                    ),
                    formRow(
                      "University Phone",
                      coach['university_phone'] ?? "",
                    ),
                    formRow(
                      "Experience",
                      "${coach['years_experience']} yrs",
                      last: true,
                    ),
                  ]),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final url = coach['certification_url'];

                          if (url != null) {
                            final uri = Uri.parse(url);

                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        },
                        child: const Text(
                          "View Certification",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          /* ---------------- ACTION BUTTONS ---------------- */

          if (coach['status'] == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Row(
                children: [

                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryOrange,
                          side: const BorderSide(color: kPrimaryOrange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: loading ? null : rejectCoach,
                        child: const Text(
                          "Reject",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: loading ? null : approveCoach,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Approve",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}