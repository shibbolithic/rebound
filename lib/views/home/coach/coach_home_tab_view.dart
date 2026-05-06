import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/models.dart';
import '../../team/team_view.dart';
import '../game_stats_view.dart';
import '../score approval/score_approval_list_view.dart';

import 'package:intl/intl.dart';

import '../Match History/match_history.dart';

/* ======================
   DESIGN TOKENS
   ====================== */

const Color kBg = Color(0xFF0F0F10);
const Color kCard = Color(0xFF1C1C1E);
const Color kPrimaryOrange = Color(0xFFFF6A2A);
const Color kTextPrimary = Colors.white;
const Color kTextSecondary = Color(0xFF9A9A9E);
const BorderRadius kRadiusXL = BorderRadius.all(Radius.circular(22));

class CoachHomeTabView extends StatefulWidget {
  const CoachHomeTabView({super.key});

  @override
  State<CoachHomeTabView> createState() => _CoachHomeTabViewState();
}

class _CoachHomeTabViewState extends State<CoachHomeTabView> {
  final supabase = Supabase.instance.client;

  List<TeamsTable> coachTeams = [];
  List<GamesTable> recentGames = [];
  Map<String, TeamsTable> teamsMap = {};

  UsersTable? currentUser;


  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoachDashboard();
  }

  Future<void> _loadCoachDashboard() async {
    setState(() => loading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

        /// USER
    final userRes = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    currentUser = UsersTable.fromMap(userRes);

    // 1. Fetch coach’s teams
    final membershipsRes = await supabase
        .from('team_memberships')
        .select()
        .eq('user_id', user.id)
        .eq('role_in_team', 'coach');

    final teamIds = membershipsRes
        .map<String>((m) => m['team_id'] as String)
        .toList();

    if (teamIds.isEmpty) {
      setState(() => loading = false);
      return;
    }

    final teamsRes =
        await supabase
        .from('team_memberships')
        .select('teams(*)')
        .eq('user_id', user.id);

    // coachTeams = teamsRes.map<TeamsTable>(TeamsTable.fromMap).toList();
    coachTeams = teamsRes
    .map<TeamsTable>((row) => TeamsTable.fromMap(row['teams']))
    .toList();


    // 2. Fetch completed games involving those teams
    final gamesRes = await supabase
        .from('games')
        .select()
        .or(
          'home_team_id.in.(${teamIds.join(',')}),'
          'away_team_id.in.(${teamIds.join(',')})',
        )
        .eq('status', 'completed').inFilter('is_pending', ['false'])
        .order('game_datetime', ascending: false)
        .limit(10);

    recentGames = gamesRes.map<GamesTable>(GamesTable.fromMap).toList();

    // 3. Gather ALL team IDs involved in these games
    final Set<String> allTeamIds = {};
    for (final g in recentGames) {
      allTeamIds.add(g.homeTeamId);
      allTeamIds.add(g.awayTeamId);
    }

    // 4. Load all those teams
    final allTeamsRes = await supabase
        .from('teams')
        .select()
        .inFilter('id', allTeamIds.toList());

    final allTeams =
        allTeamsRes.map<TeamsTable>(TeamsTable.fromMap).toList();

    teamsMap = {for (final t in allTeams) t.id: t};

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryOrange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        color: kPrimaryOrange,
        onRefresh: _loadCoachDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _header(),
            const SizedBox(height: 28),
            _sectionTitle('Your Teams', Icons.groups_rounded),
            const SizedBox(height: 14),
            _teamsScroller(),
            const SizedBox(height: 32),
_sectionHeader(
  'Recent Matches', Icons.sports_basketball_rounded,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MatchHistoryView(),
      ),
    );
  },
),
            const SizedBox(height: 12),
            if (recentGames.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'No matches played yet',
                  style: TextStyle(color: kTextSecondary),
                ),
              ),
            ...recentGames.map(_matchTile),
          ],
        ),
      ),
    );
  }

  Widget _header() {
  //final user = supabase.auth.currentUser;


  final dateText = DateFormat('EEEE, d MMM').format(DateTime.now());

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateText,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hey, ${currentUser!.displayName}!',
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      IconButton(
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: kTextPrimary,
          size: 26,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScoreApprovalListView(),
            ),
          );
        },
      ),
    ],
  );
}


  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryOrange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(
  String title,
  IconData icon, {
  VoidCallback? onTap,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      /// LEFT: ICON + TITLE
      Row(
        children: [
          Icon(icon, color: kPrimaryOrange, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),

      /// RIGHT: SHOW MORE
      if (onTap != null)
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: const Text(
            'Show more',
            style: TextStyle(
              color: kPrimaryOrange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );
}


  Widget _teamsScroller() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coachTeams.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _teamCard(coachTeams[i]),
      ),
    );
  }

  Widget _teamCard(TeamsTable team) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeamView(team: team)),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: kRadiusXL,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.grey.shade800,
              backgroundImage:
                  team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
              child: team.logoUrl == null
                  ? const Icon(Icons.shield_rounded, color: kTextPrimary)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              team.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

    final int topScore = draw ? homeScore : (homeWon ? homeScore : awayScore);
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
            /// TEAM NAMES
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
}
