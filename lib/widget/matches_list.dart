import 'package:flutter/material.dart';

class MatchesList extends StatelessWidget {
  final List games;
  const MatchesList({required this.games, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      itemBuilder: (_, i) {
        final g = games[i];
        return ListTile(
          title: Text(g['venue'] ?? 'Game'),
          subtitle: Text(g['status']),
          trailing: Text(
            '${g['home_score'] ?? '-'} : ${g['away_score'] ?? '-'}',
          ),
        );
      },
    );
  }
}