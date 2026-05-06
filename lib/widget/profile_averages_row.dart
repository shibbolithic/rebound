import 'package:flutter/material.dart';

class ProfileAveragesRow extends StatelessWidget {
  final Map? stats;
  const ProfileAveragesRow({this.stats, super.key});

  Widget _avg(String label, num value) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _avg('PPG', stats?['avg_points'] ?? 0),
        _avg('BPG', stats?['avg_rebounds'] ?? 0),
        _avg('AST', stats?['avg_assists'] ?? 0),
      ],
    );
  }
}