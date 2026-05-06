import 'package:flutter/material.dart';

class TeamsHorizontalList extends StatelessWidget {
  final List teams;
  const TeamsHorizontalList({required this.teams, super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ EMPTY STATE
    if (teams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No teams joined yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: teams.length,
        itemBuilder: (_, i) {
          final team = teams[i]['teams'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: team['logo_url'] != null
                      ? NetworkImage(team['logo_url'])
                      : null,
                  child: team['logo_url'] == null
                      ? const Icon(Icons.group)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  team['name'] ?? 'Team',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}