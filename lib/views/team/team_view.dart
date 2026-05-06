import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../home/game_stats_view.dart';
import 'team_analysis_view.dart';
import 'team_players_view.dart';

/* ======================
   DESIGN CONSTANTS
   ====================== */

const kCard = Color(0xFF1C1C1E);

class TeamView extends StatefulWidget {
  final TeamsTable team;

  const TeamView({
    super.key,
    required this.team,
  });

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  List<GamesTable> games = [];
  List<UsersTable> members = [];
  Map<String, TeamsTable> teamsMap = {};

  int matchesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int pointsScored = 0;
  int pointsConceded = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* ======================
     DATA LOADING
     ====================== */

  Future<void> _loadData() async {
    setState(() => loading = true);

    await Future.wait([
      _loadTeamsMap(),
      _loadGames(),
      _loadMembers(),
    ]);

    _calculateStats();

    setState(() => loading = false);
  }

  Future<void> _loadTeamsMap() async {
    final res = await supabase.from('teams').select();
    for (final t in res) {
      final team = TeamsTable.fromMap(t);
      teamsMap[team.id] = team;
    }
  }

  Future<void> _loadGames() async {
    final res = await supabase
        .from('games')
        .select()
        .or(
          'home_team_id.eq.${widget.team.id},away_team_id.eq.${widget.team.id}',
        ).inFilter('is_pending', ['false'])
        .eq('status', 'completed')
        .order('game_datetime', ascending: false);

    games = res.map<GamesTable>(GamesTable.fromMap).toList();
  }

  Future<void> _loadMembers() async {
    final membershipRes = await supabase
        .from('team_memberships')
        .select('user_id')
        .eq('team_id', widget.team.id);

    if (membershipRes.isEmpty) return;

    final userIds =
        membershipRes.map<String>((e) => e['user_id']).toList();

    final usersRes =
        await supabase.from('users').select().inFilter('id', userIds);

    members = usersRes.map<UsersTable>(UsersTable.fromMap).toList();
  }

  /* ======================
     STATS CALCULATION
     ====================== */

  void _calculateStats() {
    matchesPlayed = games.length;
    wins = 0;
    losses = 0;
    pointsScored = 0;
    pointsConceded = 0;

    for (final g in games) {
      final bool isHome = g.homeTeamId == widget.team.id;
      final int teamScore =
          isHome ? (g.homeScore ?? 0) : (g.awayScore ?? 0);
      final int oppScore =
          isHome ? (g.awayScore ?? 0) : (g.homeScore ?? 0);

      pointsScored += teamScore;
      pointsConceded += oppScore;

      if (teamScore > oppScore) wins++;
      if (teamScore < oppScore) losses++;
    }
  }

double get winPercentage {
  if (matchesPlayed <= 0) return 0.0;
  return (wins / matchesPlayed) * 100.0;
}

  /* ======================
     UI
     ====================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.team.name),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _teamHeader(),
                const SizedBox(height: 20),
                if (games.isNotEmpty) _topHighlights(),
                const SizedBox(height: 24),
                _membersCard(),
                const SizedBox(height: 24),
                _matchesSection(),
              ],
            ),
    );
  }

  /* ======================
     SECTIONS
     ====================== */

  Widget _teamHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: widget.team.logoUrl != null
                ? NetworkImage(widget.team.logoUrl!)
                : null,
            backgroundColor: Colors.grey.shade800,
            child: widget.team.logoUrl == null
                ? const Icon(Icons.shield, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.team.motto != null)
                  Text(
                    widget.team.motto!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _topHighlights() {
  final safeMatches = matchesPlayed;
  final safeWins = wins;
  final safeLosses = losses;
  final safeWinPct =
      safeMatches == 0 ? '0.0' : winPercentage.toStringAsFixed(1);
  final safeFor = pointsScored;
  final safeAgainst = pointsConceded;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Top Highlights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TeamAnalysisView(teamId: widget.team.id),
                ),
              );
            },
            child: const Text('Show more'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _statTile('Matches', '$safeMatches'),
            _statTile('Wins', '$safeWins'),
            _statTile('Losses', '$safeLosses'),
            _statTile('Win %', safeWinPct),
            _statTile('Points For', '$safeFor'),
            _statTile('Points Against', '$safeAgainst'),
          ],
        ),
      ),
    ],
  );
}

  Widget _membersCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamPlayersView(teamId: widget.team.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Members',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${members.length} members',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Matches',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...games.map(_matchTile),
      ],
    );
  }

  /* ======================
     MATCH TILE (YOUR LOGIC)
     ====================== */

  Widget _matchTile(GamesTable g) {
    final homeTeam = teamsMap[g.homeTeamId];
    final awayTeam = teamsMap[g.awayTeamId];

    final homeScore = g.homeScore ?? 0;
    final awayScore = g.awayScore ?? 0;

    final bool homeWon = homeScore > awayScore;
    final bool draw = homeScore == awayScore;

    final String topTeamName = draw
        ? homeTeam?.name ?? 'Unknown'
        : (homeWon
            ? homeTeam?.name ?? 'Unknown'
            : awayTeam?.name ?? 'Unknown');

    final String bottomTeamName = draw
        ? awayTeam?.name ?? 'Unknown'
        : (homeWon
            ? awayTeam?.name ?? 'Unknown'
            : homeTeam?.name ?? 'Unknown');

    final int topScore =
        draw ? homeScore : (homeWon ? homeScore : awayScore);
    final int bottomScore =
        draw ? awayScore : (homeWon ? awayScore : homeScore);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameStatsView(gameId: g.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topTeamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bottomTeamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$topScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$bottomScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /* ======================
     SMALL HELPERS
     ====================== */

  Widget _statTile(String label, String value) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
