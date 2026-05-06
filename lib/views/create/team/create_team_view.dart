import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../controllers/create_team_controller.dart';
import '../../../widget/user_avatar_chip.dart';
import 'select_users_modal.dart';

// ======================
// DARK iOS TOKENS
// ======================

const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kMuted = Color(0xFF8E8E93);
const kOrange = Color(0xFFFF6B35);
const kText = Colors.white;

// ======================
// USER MODEL (UNCHANGED)
// ======================

class AppUser2 {
  final String id;
  final String displayName;
  final String? profilePicture;

  AppUser2({
    required this.id,
    required this.displayName,
    this.profilePicture,
  });

  factory AppUser2.fromMap(Map<String, dynamic> map) {
    return AppUser2(
      id: map['id'],
      displayName: map['display_name'],
      profilePicture: map['profile_picture'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppUser2 && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ======================
// VIEW
// ======================

class CreateTeamView extends StatefulWidget {
  const CreateTeamView({super.key});

  @override
  State<CreateTeamView> createState() => _CreateTeamViewState();
}

class _CreateTeamViewState extends State<CreateTeamView> {
  final CreateTeamController controller = CreateTeamController();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController mottoCtrl = TextEditingController();

  List<AppUser2> coaches = [];
  List<AppUser2> members = [];

  XFile? teamLogo;
  Uint8List? teamLogoBytes;

  bool isLoading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    mottoCtrl.dispose();
    super.dispose();
  }

  ImageProvider? get teamLogoProvider {
    if (teamLogo != null) {
      if (kIsWeb) return MemoryImage(teamLogoBytes!);
      return FileImage(File(teamLogo!.path));
    }
    return null;
  }

  // ======================
  // UI
  // ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: const BackButton(color: kText),
        title: const Text(
          'Create Team',
          style: TextStyle(color: kText, fontWeight: FontWeight.w600),
        ),
      ),
      body: AbsorbPointer(
        absorbing: isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────── TEAM NAME + LOGO ─────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: pickLogo,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        

                        color: Colors.white,
                        shape: BoxShape.circle,
                        image: teamLogoProvider != null
                            ? DecorationImage(
                                image: teamLogoProvider!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: teamLogoProvider == null
                          ? const Icon(
                              CupertinoIcons.camera_fill,
                              color: Colors.black,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _roundedInput(
                      controller: nameCtrl,
                      hint: 'Team name',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ───────── MOTTO ─────────
              _roundedInput(
                controller: mottoCtrl,
                hint: 'Team motto',
              ),

              const SizedBox(height: 32),

              // ───────── COACHES ─────────
              const Text(
                'Coach',
                style: TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _chipRow(coaches, selectCoaches),

              const SizedBox(height: 28),

              // ───────── MEMBERS ─────────
              const Text(
                'Members',
                style: TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _chipRow(members, selectMembers),

              const Spacer(),

              // ───────── CREATE BUTTON ─────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: isLoading ? null : createTeam,
                  child: isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Create',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================
  // UI HELPERS
  // ======================

Widget _roundedInput({
  required TextEditingController controller,
  required String hint,
}) {
  return Container(
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: TextField(
      controller: controller,
      cursorColor: kText,
      style: const TextStyle(
        color: kText,
        fontSize: 16,
      ),
      decoration: const InputDecoration(
        hintText: null, // set below
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,

        // 🚨 THIS IS CRITICAL
        filled: true,
        fillColor: Colors.transparent,

        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 14),
      ).copyWith(
        hintText: hint,
        hintStyle: const TextStyle(
          color: kMuted,
          fontSize: 15,
        ),
      ),
    ),
  );
}


  Widget _chipRow(List<AppUser2> users, VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _addButton(onAdd),
          const SizedBox(width: 8),
          ...users.map(
            (u) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: UserAvatarChip(user: u),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton(VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.add,
            color: Colors.black,
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add',
          style: TextStyle(
            color: kMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}


  // ======================
  // LOGIC (UNCHANGED)
  // ======================

  Future<void> pickLogo() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (img != null) {
      if (kIsWeb) teamLogoBytes = await img.readAsBytes();
      setState(() => teamLogo = img);
    }
  }

  Future<void> selectCoaches() async {
    final users = await controller.fetchCoaches();
    if (!mounted) return;

    final result = await showModalBottomSheet<List<AppUser2>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      builder: (_) => SelectUsersModal(
        title: 'Select Coaches',
        users: users,
        max: 2,
      ),
    );

    if (result != null) setState(() => coaches = result);
  }

  Future<void> selectMembers() async {
    final users = await controller.fetchAthletes();
    if (!mounted) return;

    final result = await showModalBottomSheet<List<AppUser2>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      builder: (_) => SelectUsersModal(
        title: 'Select Members',
        users: users,
        max: 12,
      ),
    );

    if (result != null) setState(() => members = result);
  }

  Future<void> createTeam() async {
    if (nameCtrl.text.trim().isEmpty) {
      showError('Team name is required');
      return;
    }

    setState(() => isLoading = true);

    try {
      String? logoUrl;
      if (teamLogo != null) {
        logoUrl = await controller.uploadTeamLogo1(file: teamLogo!);
      }

      await controller.createTeam(
        name: nameCtrl.text.trim(),
        motto: mottoCtrl.text.trim(),
        logoUrl: logoUrl,
        coaches: coaches,
        members: members,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
