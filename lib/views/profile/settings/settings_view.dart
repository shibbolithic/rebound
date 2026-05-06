  import 'dart:io';

  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';


  import '../../../controllers/profile_controller.dart';
  import 'package:flutter/foundation.dart';

  class SettingsView extends StatefulWidget {
    final Map<String, dynamic> user;
    const SettingsView({super.key, required this.user});

    @override
    State<SettingsView> createState() => _SettingsViewState();
  }

  class _SettingsViewState extends State<SettingsView> {
    final _controller = ProfileController();

    late TextEditingController nameCtrl;
    late TextEditingController bioCtrl;
    late TextEditingController heightCtrl;
    late TextEditingController weightCtrl;
    late TextEditingController expCtrl;

    String? position;
    bool loading = false;

    // ======================
    // IMAGE STATE
    // ======================

    XFile? profileImage;
    XFile? coverImage;


  Uint8List? profileImageBytes;
  Uint8List? coverImageBytes;

    // ======================
    // INIT
    // ======================

    @override
    @override
void initState() {
  super.initState();

  nameCtrl = TextEditingController(
    text: widget.user['display_name'] ?? '',
  );

  bioCtrl = TextEditingController(
    text: widget.user['bio'] ?? '',
  );

  final athlete = widget.user['athlete'];

  // Height
  heightCtrl = TextEditingController(
    text: athlete != null && athlete['height_cm'] != null
        ? athlete['height_cm'].toString()
        : '',
  );

  // Weight
  weightCtrl = TextEditingController(
    text: athlete != null && athlete['weight_kg'] != null
        ? athlete['weight_kg'].toString()
        : '',
  );

  // Experience
  expCtrl = TextEditingController(
    text: athlete != null && athlete['experience_years'] != null
        ? athlete['experience_years'].toString()
        : '',
  );

  // Position
  position = athlete != null ? athlete['position'] : null;
}


    // ======================
    // IMAGE PROVIDERS
    // ======================
  ImageProvider? get profileImageProvider {
    if (profileImage != null) {
      if (kIsWeb) {
        return MemoryImage(profileImageBytes!);
      } else {
        return FileImage(File(profileImage!.path));
      }
    }

    final url = widget.user['profile_picture'];
    if (url != null && url.toString().trim().isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  ImageProvider? get coverImageProvider {
    if (coverImage != null) {
      if (kIsWeb) {
        return MemoryImage(coverImageBytes!);
      } else {
        return FileImage(File(coverImage!.path));
      }
    }

    final url = widget.user['cover_picture'];
    if (url != null && url.toString().trim().isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }


    // ======================
    // IMAGE PICKING
    // ======================

    Future<void> pickProfileImage() async {
    final img = await _controller.pickImage();
    if (img != null) {
      if (kIsWeb) {
        profileImageBytes = await img.readAsBytes();
      }
      setState(() => profileImage = img);
    }
  }

  Future<void> pickCoverImage() async {
    final img = await _controller.pickImage();
    if (img != null) {
      if (kIsWeb) {
        coverImageBytes = await img.readAsBytes();
      }
      setState(() => coverImage = img);
    }
  }


    // ======================
    // SAVE
    // ======================

    Future<void> _save() async {
  setState(() => loading = true);

  final userId = widget.user['id'];
  final role = widget.user['role'];

  // ======================
  // IMAGES (retain old if not changed)
  // ======================

  String? profileUrl = widget.user['profile_picture'];
  String? coverUrl = widget.user['cover_picture'];

  if (profileImage != null) {
    profileUrl = await _controller.uploadProfileImage(
      file: profileImage!,
      userId: userId,
      isCover: false,
    );
  }

  if (coverImage != null) {
    coverUrl = await _controller.uploadProfileImage(
      file: coverImage!,
      userId: userId,
      isCover: true,
    );
  }

  // ======================
  // CORE USER UPDATE
  // ======================

  await _controller.updateUserCore(
    userId: userId,
    displayName: nameCtrl.text.trim().isNotEmpty
        ? nameCtrl.text.trim()
        : widget.user['display_name'],
    bio: bioCtrl.text.trim().isNotEmpty
        ? bioCtrl.text.trim()
        : widget.user['bio'],
    profileUrl: profileUrl,
    coverUrl: coverUrl,
  );

  // ======================
  // ATHLETE PROFILE UPDATE
  // ======================

  if (role == 'athlete') {
    await _controller.upsertAthleteProfile(
      userId: userId,

      heightCm: heightCtrl.text.trim().isNotEmpty
          ? double.tryParse(heightCtrl.text)
          : null,

      weightKg: weightCtrl.text.trim().isNotEmpty
          ? double.tryParse(weightCtrl.text)
          : null,

      experienceYears: expCtrl.text.trim().isNotEmpty
          ? int.tryParse(expCtrl.text)
          : null,

      position: position,
    );
  }

  setState(() => loading = false);
  Navigator.pop(context);
}


    // ======================
    // LOGOUT
    // ======================

    Future<void> _logout() async {
      await _controller.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }

    // ======================
    // UI
    // ======================

    @override
    Widget build(BuildContext context) {
return CupertinoPageScaffold(
  backgroundColor: const Color(0xFF0B0B0F), // TRUE iOS dark background
  navigationBar: CupertinoNavigationBar(
    backgroundColor: const Color(0xFF0B0B0F),
    border: null, // removes bottom divider
    middle: const Text(
      'Settings',
      style: TextStyle(color: CupertinoColors.white),
    ),
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: loading ? null : _save,
      child: loading
          ? const CupertinoActivityIndicator()
          : const Text(
              'Save',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
    ),
  ),
  child: SafeArea(
    child: Container(
          color: const Color(0xFF0B0B0F), // FULL SCREEN BLACK
child: ListView(
  padding: EdgeInsets.zero,
  physics: const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  ),
  children: [
    coverAndAvatar(),
    const SizedBox(height: 56),

              /// PROFILE
CupertinoFormSection.insetGrouped(
  backgroundColor: Colors.transparent,
  decoration: const BoxDecoration(
    color: Color(0xFF0B0B0F),
  ),
  header: const Text(
    'PROFILE',
    style: TextStyle(color: CupertinoColors.white),
  ),
  children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CupertinoFloatingField(
        controller: nameCtrl,
        label: 'Display Name',
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CupertinoFloatingField(
        controller: bioCtrl,
        label: 'Bio',
        maxLines: 3,
      ),
    ),
  ],
),


              /// ATHLETE DETAILS
if (widget.user['role'] == 'athlete')
  CupertinoFormSection.insetGrouped(
    backgroundColor: Colors.transparent, // section background
  decoration: const BoxDecoration(
    color: Color(0xFF0B0B0F),
  ),
  header: const Text(
    'ATHLETE DETAILS',
    style: TextStyle(color: CupertinoColors.white),
  ),

    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CupertinoFloatingField(
          controller: heightCtrl,
          label: 'Height (cm)',
          keyboardType: TextInputType.number,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CupertinoFloatingField(
          controller: weightCtrl,
          label: 'Weight (kg)',
          keyboardType: TextInputType.number,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CupertinoFloatingField(
          controller: expCtrl,
          label: 'Experience (years)',
          keyboardType: TextInputType.number,
        ),
      ),

      /// Position selector (iOS-style)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          onPressed: () async {
            final p = await showCupertinoModalPopup<String>(
              context: context,
              builder: (_) => _positionPicker(),
            );
            if (p != null) setState(() => position = p);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                position ?? 'Position',
                style: TextStyle(
                  color: position == null
                      ? CupertinoColors.systemGrey2
                      : CupertinoColors.white,
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      ),
    ],
  ),

              /// LOGOUT
CupertinoFormSection.insetGrouped(
   backgroundColor: Colors.transparent,
  decoration: const BoxDecoration(
    color: Color(0xFF0B0B0F),
  ),
  header: const Text(
    'LOGOUT',
    style: TextStyle(color: CupertinoColors.white),
  ),
                children: [
                  CupertinoButton(
                    onPressed: _logout,
                    child: const Text(
                      'Log Out',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      );
    }

    // ======================
    // HELPERS
    // ======================

    Widget _numberField(String label, TextEditingController ctrl) {
      return CupertinoFormRow(
        prefix: Text(label),
        child: CupertinoTextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          placeholder: label,
        ),
      );
    }

    Widget _positionPicker() {
      const positions = ['PG', 'SG', 'SF', 'PF', 'C'];

      return CupertinoActionSheet(
        title: const Text('Select Position'),
        actions: positions
            .map(
              (p) => CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, p),
                child: Text(p),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      );
    }

    // ======================
    // COVER + AVATAR
    // ======================

    Widget coverAndAvatar() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: pickCoverImage,
            child: Container(
              // height: 180,
  height: 56,

              width: double.infinity,
              // color: const Color(0xFF1C1C1E),
  color: const Color(0xFF0B0B0F),
              child: coverImageProvider != null
                  ? Image(image: coverImageProvider!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.white30,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: pickProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFF2C2C2E),
                      backgroundImage: profileImageProvider,
                      child: profileImageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white30,
                            )
                          : null,
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black,
                        child: Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }


class CupertinoFloatingField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int maxLines;

  const CupertinoFloatingField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<CupertinoFloatingField> createState() =>
      _CupertinoFloatingFieldState();
}

class _CupertinoFloatingFieldState extends State<CupertinoFloatingField> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Focus(
      onFocusChange: (f) => setState(() => focused = f),
      child: Stack(
        children: [
          CupertinoTextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
            ),
            cursorColor: CupertinoColors.activeBlue,
            padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E), // iOS dark card
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused
                    ? CupertinoColors.activeBlue
                    : const Color(0xFF2C2C2E),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          /// Floating Label
          Positioned(
            left: 14,
            top: hasText || focused ? 6 : 22,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: hasText || focused ? 11 : 15,
                color: hasText || focused
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
              child: Text(widget.label),
            ),
          ),
        ],
      ),
    );
  }
}
