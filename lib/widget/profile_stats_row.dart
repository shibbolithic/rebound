import 'package:flutter/material.dart';

class ProfileStatsRow extends StatelessWidget {
  final Map? athlete;
  final Map? stats;

  const ProfileStatsRow({this.athlete, this.stats, super.key});

  Widget _item(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item('Position', athlete?['position'] ?? '-'),
          _item('Matches', stats?['games_played']?.toString() ?? '0'),
          _item('Height', '${athlete?['height_cm'] ?? '-'} cm'),
          _item('Weight', '${athlete?['weight_kg'] ?? '-'} kg'),
        ],
      ),
    );
  }
}