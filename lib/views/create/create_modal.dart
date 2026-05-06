import 'package:flutter/material.dart';
import 'package:rebound/views/create/game/create_game_view.dart';
import 'package:rebound/views/create/team/create_team_view.dart';

/* ======================
   THEME TOKENS
   ====================== */

const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kDivider = Color(0xFF2C2C2E);
const kMuted = Color(0xFF8E8E93);
const kOrange = Color(0xFFFF6B35);

class CreateModal extends StatelessWidget {
  const CreateModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: kDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          _CreateItem(
            icon: Icons.sports_basketball_outlined,
            label: 'Game',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateGameView(),
                ),
              );
            },
          ),

          const Divider(color: kDivider, height: 1),

          _CreateItem(
            icon: Icons.group_outlined,
            label: 'Team',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateTeamView(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CreateItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreateItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kOrange),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      splashColor: kOrange.withOpacity(0.15),
      hoverColor: kOrange.withOpacity(0.05),
    );
  }
}
