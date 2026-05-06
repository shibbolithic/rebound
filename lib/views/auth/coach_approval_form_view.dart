import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoachApprovalFormView extends StatefulWidget {
  const CoachApprovalFormView({super.key});

  @override
  State<CoachApprovalFormView> createState() =>
      _CoachApprovalFormViewState();
}

class _CoachApprovalFormViewState
    extends State<CoachApprovalFormView> {

  final supabase = Supabase.instance.client;

  final specializationCtrl = TextEditingController();
  final universityCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final pocNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final experienceCtrl = TextEditingController();

  bool loading = false;
  String? certificateUrl;

  Future<void> pickAndUploadPdf(String userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.first;
    final filePath = 'certificates/$userId.pdf';

    await supabase.storage
        .from('coach-certificates')
        .uploadBinary(filePath, file.bytes!,
            fileOptions: const FileOptions(upsert: true));

    final publicUrl = supabase.storage
        .from('coach-certificates')
        .getPublicUrl(filePath);

    setState(() {
      certificateUrl = publicUrl;
    });
  }

  Future<void> submitForApproval() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (certificateUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload certification PDF")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.from('coach_approval').upsert({
        'user_id': user.id,
        'specialisation': specializationCtrl.text.trim(),
        'certification_url': certificateUrl,
        'university_name': universityCtrl.text.trim(),
        'year_of_passing': int.parse(yearCtrl.text.trim()),
        'university_poc_name': pocNameCtrl.text.trim(),
        'university_phone': phoneCtrl.text.trim(),
        'years_experience': int.parse(experienceCtrl.text.trim()),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      Navigator.pushReplacementNamed(context, '/coach-pending');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Coach Verification")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            TextField(
              controller: specializationCtrl,
              decoration: const InputDecoration(
                labelText: "Specialisation",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: universityCtrl,
              decoration: const InputDecoration(
                labelText: "University Name",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Year of Passing",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: pocNameCtrl,
              decoration: const InputDecoration(
                labelText: "University POC Name",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "University Phone",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: experienceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Years of Experience",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final user = supabase.auth.currentUser;
                if (user != null) {
                  pickAndUploadPdf(user.id);
                }
              },
              child: const Text("Upload Certification PDF"),
            ),

            if (certificateUrl != null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Certificate uploaded",
                  style: TextStyle(color: Colors.green),
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : submitForApproval,
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Send for Approval"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}