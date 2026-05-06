import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../views/create/team/create_team_view.dart';

class UserAvatarChip extends StatelessWidget {
  final AppUser2 user;

  const UserAvatarChip({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: user.profilePicture != null
              ? NetworkImage(user.profilePicture!)
              : null,
          child: user.profilePicture == null
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
  user.displayName,
  style: const TextStyle(
    fontSize: 11,
    color: Colors.white, // 👈 THIS FIXES IT
    fontWeight: FontWeight.w500,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
),

      ],
    );
  }
}