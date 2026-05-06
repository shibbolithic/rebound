import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/models.dart';
import '../../home/game_stats_view.dart';

class MatchHistoryView extends StatefulWidget {
  const MatchHistoryView({super.key});

  @override
  State<MatchHistoryView> createState() => _MatchHistoryViewState();
}

class _MatchHistoryViewState extends State<MatchHistoryView> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  // 🔍 SEARCH
  final TextEditingController _searchCtrl = TextEditingController();

  // DATA
  final List<_MatchItem> allItems = [];
  List<_MatchItem> filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  // ============================
  // LOAD MATCHES
  // ============================
  Future<void> _loadMatches() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1️⃣ Fetch games
    final gamesRes = await supabase
        .from('games')
        .select().inFilter('is_pending', ['false'])
        .order('game_datetime', ascending: false);

    final games =
        gamesRes.map<GamesTable>((e) => GamesTable.fromMap(e)).toList();

    if (games.isEmpty) {
      setState(() => loading = false);
      return;
    }

    // 2️⃣ Fetch teams
    final teamIds = <String>{};
    for (final g in games) {
      teamIds.add(g.homeTeamId);
      teamIds.add(g.awayTeamId);
    }

    final teamsRes = await supabase
        .from('teams')
        .select()
        .inFilter('id', teamIds.toList());

    final Map<String, TeamsTable> teamsMap = {};
    for (final t in teamsRes) {
      final team = TeamsTable.fromMap(t);
      teamsMap[team.id] = team;
    }

    // 3️⃣ Fetch player stats
    final statsRes = await supabase
        .from('player_game_stats')
        .select()
        .inFilter('game_id', games.map((g) => g.id).toList());

    final Map<String, List<PlayerGameStatsTable>> statsByGame = {};

    for (final r in statsRes) {
      final stat = PlayerGameStatsTable.fromMap(r);
      statsByGame.putIfAbsent(stat.gameId, () => []);
      statsByGame[stat.gameId]!.add(stat);
    }

    // 4️⃣ Build match items
    for (final game in games) {
      final gameStats = statsByGame[game.id] ?? [];

      final homePlayers =
          gameStats.where((s) => s.teamId == game.homeTeamId).toList();
      final awayPlayers =
          gameStats.where((s) => s.teamId == game.awayTeamId).toList();

      int sum(List<PlayerGameStatsTable> l,
              int Function(PlayerGameStatsTable) f) =>
          l.fold(0, (a, b) => a + f(b));

      final homeStats = _TeamStats(
        fieldGoals: sum(homePlayers, (e) => e.made2 + e.made3),
        threePoints: sum(homePlayers, (e) => e.made3),
        freeThrows: sum(homePlayers, (e) => e.madeFt),
      );

      final awayStats = _TeamStats(
        fieldGoals: sum(awayPlayers, (e) => e.made2 + e.made3),
        threePoints: sum(awayPlayers, (e) => e.made3),
        freeThrows: sum(awayPlayers, (e) => e.madeFt),
      );

      allItems.add(
        _MatchItem(
          game: game,
          homeTeam: teamsMap[game.homeTeamId],
          awayTeam: teamsMap[game.awayTeamId],
          homeStats: homeStats,
          awayStats: awayStats,
        ),
      );
    }

    setState(() {
      filteredItems = List.from(allItems);
      loading = false;
    });
  }

  // ============================
  // SEARCH LOGIC
  // ============================
  void _onSearch(String query) {
    final q = query.toLowerCase().trim();

    setState(() {
      if (q.isEmpty) {
        filteredItems = List.from(allItems);
      } else {
        filteredItems = allItems.where((item) {
          final home = item.homeTeam?.name.toLowerCase() ?? '';
          final away = item.awayTeam?.name.toLowerCase() ?? '';
          return home.contains(q) || away.contains(q);
        }).toList();
      }
    });
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30,),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Matches'),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search games',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // 📋 LIST
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    children: filteredItems.map(_card).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(_MatchItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameStatsView(gameId: item.game.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _teams(item),
            const SizedBox(height: 14),
            _statRow('Field Goals',
                item.homeStats.fieldGoals,
                item.awayStats.fieldGoals),
            _statRow('3P Field Goals',
                item.homeStats.threePoints,
                item.awayStats.threePoints),
            _statRow('Free Throws',
                item.homeStats.freeThrows,
                item.awayStats.freeThrows),
          ],
        ),
      ),
    );
  }

  Widget _teams(_MatchItem item) {
    return Row(
      children: [
        _team(item.homeTeam, item.game.homeScore ?? 0),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('VS', style: TextStyle(color: Colors.white70)),
        ),
        _team(item.awayTeam, item.game.awayScore ?? 0),
      ],
    );
  }

  Widget _team(TeamsTable? team, int points) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade800,
            child: team?.logoUrl != null && team!.logoUrl!.isNotEmpty
                ? Image.network(team.logoUrl!)
                : const Icon(
                    Icons.sports_basketball,
                    size: 18,
                    color: Colors.white70,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            team?.name ?? 'Unknown Team',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '$points pts',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int left, int right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text('$left',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text('$right',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ============================
// INTERNAL MODELS
// ============================
class _MatchItem {
  final GamesTable game;
  final TeamsTable? homeTeam;
  final TeamsTable? awayTeam;
  final _TeamStats homeStats;
  final _TeamStats awayStats;

  _MatchItem({
    required this.game,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeStats,
    required this.awayStats,
  });
}

class _TeamStats {
  final int fieldGoals;
  final int threePoints;
  final int freeThrows;

  const _TeamStats({
    required this.fieldGoals,
    required this.threePoints,
    required this.freeThrows,
  });
}
