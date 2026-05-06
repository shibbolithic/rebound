import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/Match History/match_history.dart';
import '../home/Analysis/analysis_view.dart';

import '../home/Analysis/player_analytics_view.dart';
import '../home/game_stats_view.dart';

import '../../models/models.dart';
import 'score approval/score_approval_list_view.dart';


class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {


  final supabase = Supabase.instance.client;

  UsersTable? currentUser;
  MvPlayerSeasonStatsTable? seasonStats;

  int totalGamesPlayed = 0;
int totalPointsScored = 0;


  double twoPtPct = 0;
  double threePtPct = 0;
  double ftPct = 0;

  List<GamesTable> recentGames = [];
  Map<String, TeamsTable> teamsMap = {};


  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

Future<void> _loadAll() async {
  try {
    final authUser = supabase.auth.currentUser;

    if (authUser == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    /// ---------------- USER ----------------
    final userRes = await supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (userRes != null) {
      currentUser = UsersTable.fromMap(userRes);
    }

    /// ---------------- RECENT GAMES ----------------
    final gamesRes = await supabase
        .from('games')
        .select()
        .eq('is_pending', false)
        .order('game_datetime', ascending: false)
        .limit(5);

    recentGames =
        (gamesRes as List)
            .map((e) => GamesTable.fromMap(e))
            .toList();

    /// ---------------- FETCH TEAMS USED IN RECENT GAMES ----------------
    final teamIds = <String>{};

    for (final g in recentGames) {
      teamIds.add(g.homeTeamId);
      teamIds.add(g.awayTeamId);
    }

    if (teamIds.isNotEmpty) {
      final teamsRes = await supabase
          .from('teams')
          .select()
          .inFilter('id', teamIds.toList());

      for (final t in teamsRes) {
        final team = TeamsTable.fromMap(t);
        teamsMap[team.id] = team;
      }
    }

    /// ---------------- PLAYER TOTAL STATS ----------------
    if (currentUser?.role == 'athlete') {
      final statsRows = await supabase
          .from('player_game_stats')
          .select(
              'game_id, total_points, made_2, missed_2, made_3, missed_3')
          .eq('player_id', authUser.id);

      final Set<String> uniqueGames = {};
      int points = 0;

      int m2 = 0, x2 = 0, m3 = 0, x3 = 0, mft = 0, xft = 0;

      for (final r in statsRows) {
        uniqueGames.add(r['game_id']);
        points += (r['total_points'] ?? 0) as int;

        m2 += (r['made_2'] ?? 0) as int;
        x2 += (r['missed_2'] ?? 0) as int;

        m3 += (r['made_3'] ?? 0) as int;
        x3 += (r['missed_3'] ?? 0) as int;

       // mft += (r['made_ft'] ?? 0) as int;
        //xft += (r['missed_ft'] ?? 0) as int;
      }

      totalGamesPlayed = uniqueGames.length;
      totalPointsScored = points;

      twoPtPct = (m2 + x2) == 0 ? 0 : m2 / (m2 + x2);
      threePtPct = (m3 + x3) == 0 ? 0 : m3 / (m3 + x3);
      ftPct = (twoPtPct + threePtPct) == 0 ? 0 : (twoPtPct+threePtPct) / (twoPtPct + threePtPct);
    }
  } catch (e) {
    debugPrint("HomeTabView Load Error: $e");
  }

  if (mounted) {
    setState(() => loading = false);
  }
}

  bool get isCoach => currentUser?.role == 'coach';

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dateText = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hey, ${currentUser!.displayName}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                isCoach
                    ? IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ScoreApprovalListView(),
                            ),
                          );
                        },
                      )
                    : CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            currentUser!.profilePicture != null
                                ? NetworkImage(
                                    currentUser!.profilePicture!)
                                : null,
                        backgroundColor: Colors.grey.shade800,
                      ),
              ],
            ),

            const SizedBox(height: 24),

            /// SUMMARY HEADER
           _sectionHeader(
  'Summary',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PlayerAnalyticsView(),
      ),
    );
  },
),

            /// SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _ring(
                          '2 Point\nEfficiency', twoPtPct, Colors.green),
                      _ring(
                          '3 Point\nEfficiency', threePtPct, Colors.red),
                      _ring('Free Throw\nEfficiency',
                          ftPct, Colors.cyan),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _statTile(
                        'Total Games Played',
                        totalGamesPlayed,
                      ),
                      _statTile(
                        'Total Points Scored',
                        totalPointsScored,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// RECENT MATCHES
            _sectionHeader(
  'Recent Matches',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MatchHistoryView(),
      ),
    );
  },
),
            const SizedBox(height: 8),

recentGames.isEmpty
    ? Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: const [
            Icon(
              Icons.sports_basketball,
              color: Colors.grey,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              "No matches yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Start playing and log your first game!",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
    : Column(
        children: recentGames.map(_matchTile).toList(),
      ),          ],
        ),
      ),
    );
  }

  /// ----------------- UI HELPERS -----------------

Widget _sectionHeader(String title, {VoidCallback? onTap}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      GestureDetector(
        onTap: onTap,
        child: const Text(
          'Show More',
          style: TextStyle(
            color: Colors.red,
            fontSize: 13,
          ),
        ),
      ),
    ],
  );
}


  Widget _ring(String label, double value, Color color) {
    return CircularPercentIndicator(
      radius: 36,
      lineWidth: 6,
      percent: value.clamp(0, 1),
      center: Text(
        '${(value * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      progressColor: color,
      backgroundColor: Colors.grey.shade800,
      footer: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _statTile(String title, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

Widget _matchTile(GamesTable g) {
  final homeTeam = teamsMap[g.homeTeamId];
  final awayTeam = teamsMap[g.awayTeamId];

  final homeScore = g.homeScore ?? 0;
  final awayScore = g.awayScore ?? 0;

  final bool homeWon = homeScore > awayScore;
  final bool draw = homeScore == awayScore;

  final String topTeam =
      homeWon || draw ? homeTeam?.name ?? '' : awayTeam?.name ?? '';
  final String bottomTeam =
      homeWon || draw ? awayTeam?.name ?? '' : homeTeam?.name ?? '';

  final int topScore = homeWon || draw ? homeScore : awayScore;
  final int bottomScore = homeWon || draw ? awayScore : homeScore;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameStatsView(
            gameId: g.id, // ✅ PASS GAME ID
            // game: g,      // (optional but recommended)
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// TEAM NAMES
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topTeam,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bottomTeam,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          /// SCORE
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
                style: TextStyle(
                  color: Colors.grey.shade400,
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
}
