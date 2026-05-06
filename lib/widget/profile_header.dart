import 'package:flutter/material.dart';
import '../../views/profile/settings/settings_view.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  const ProfileHeader({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final String coverUrl =
        (user['cover_picture'] as String?)?.trim().isNotEmpty == true
            ? user['cover_picture']
            : 'https://geexguusxuelasylkvlh.supabase.co/storage/v1/object/public/publics/km/20250509_174024.jpg';

    final String? profileUrl =
        (user['profile_picture'] as String?)?.trim().isNotEmpty == true
            ? user['profile_picture']
            : null;

    final String displayName =
        (user['display_name'] as String?)?.trim().isNotEmpty == true
            ? user['display_name']
            : 'No Name';

    final String bio =
        (user['bio'] as String?)?.trim().isNotEmpty == true
            ? user['bio']
            : '';

    return Stack(
      children: [
        Image.network(
          coverUrl,
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
        ),

        /// SETTINGS BUTTON
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsView(user: user),
                ),
              );
            },
          ),
        ),

        Positioned(
          top: 200,
          left: 0,
          right: 0,
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage:
                    profileUrl != null ? NetworkImage(profileUrl) : null,
                child: profileUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (bio.isNotEmpty)
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        )
      ],
    );
  }
}
