import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/models.dart';
import '../../profile/settings/settings_view.dart';
import '../game_stats_view.dart';

import '../Match History/match_history.dart';


// ======================
// iOS DARK THEME TOKENS
// ======================

const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kMuted = Color(0xFF8E8E93);
const kPrimary = Color(0xFFFF7A1A);


const Color kPrimaryOrange = Color(0xFFFF6A2A);
const Color kTextPrimary = Colors.white;
const Color kTextSecondary = Color(0xFF9A9A9E);
const BorderRadius kRadiusXL = BorderRadius.all(Radius.circular(22));


class CoachProfileView extends StatefulWidget {
  const CoachProfileView({super.key});

  @override
  State<CoachProfileView> createState() => _CoachProfileViewState();
}

class _CoachProfileViewState extends State<CoachProfileView> {
  final supabase = Supabase.instance.client;

  UsersTable? userProfile;
  CoachProfilesTable? coachProfile;

  List<TeamsTable> userTeams = [];
    Map<String, TeamsTable> teamsMap = {};

    List<GamesTable> recentGames = [];



  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /* ======================
     DATA LOADING
     ====================== */

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;

      final userId = authUser.id;

      /// ---------- USER ----------
      final userRes = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      userProfile = UsersTable.fromMap(userRes);

      /// ---------- COACH PROFILE ----------
      final coachRes = await supabase
          .from('coach_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (coachRes != null) {
        coachProfile = CoachProfilesTable.fromMap(coachRes);
      }

      /// ---------- TEAM MEMBERSHIPS ----------
      final membershipRes = await supabase
          .from('team_memberships')
          .select()
          .eq('user_id', userId);

      final memberships = membershipRes
          .map<TeamMembershipsTable>(
              (e) => TeamMembershipsTable.fromMap(e))
          .toList();

      final teamIds = memberships.map((e) => e.teamId).toList();

if (teamIds.isEmpty) {
  userTeams = [];
  recentGames = [];
  teamsMap = {};
} else {
  final teamsRes = await supabase
      .from('teams')
      .select()
      .inFilter('id', teamIds);

  userTeams =
      teamsRes.map<TeamsTable>((e) => TeamsTable.fromMap(e)).toList();

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

  final allTeamIds = <String>{};
  for (final g in recentGames) {
    allTeamIds.add(g.homeTeamId);
    allTeamIds.add(g.awayTeamId);
  }

  if (allTeamIds.isNotEmpty) {
    final allTeamsRes = await supabase
        .from('teams')
        .select()
        .inFilter('id', allTeamIds.toList());

    final allTeams =
        allTeamsRes.map<TeamsTable>(TeamsTable.fromMap).toList();

    teamsMap = {for (final t in allTeams) t.id: t};
  }
}
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() => isLoading = false);
    }
  }

  /* ======================
     UI
     ====================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _profileHeader(context),
                            _nameSection(),
                            const SizedBox(height: 24),
                            if (userTeams.length > 0) _teamsSection(),
                            const SizedBox(height: 24),
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
            if (recentGames.length == 0)
  const Padding(
    padding: EdgeInsets.only(top: 12),
    child: Text(
      'No matches played yet',
      style: TextStyle(color: kTextSecondary),
    ),
  )
else
  ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: recentGames.length,
    itemBuilder: (_, i) => _matchTile(recentGames[i]),
  ),



                          ],
                        ),
                      ),
          ),

          /// ⚙️ SETTINGS
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.settings, size: 26),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SettingsView(user: userProfile!.toMap()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /* ======================
     SECTIONS
     ====================== */

  Widget _profileHeader(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final avatarSize = width * 0.30;

    return SizedBox(
      height: 150 + avatarSize / 2,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          /// COVER
          SizedBox(
            height: 150,
            width: double.infinity,
            child: userProfile?.coverPicture != null
                ? Image.network(
                    userProfile!.coverPicture!,
                    fit: BoxFit.cover,
                  )
                : Container(color: kCard),
          ),

          /// GRADIENT
          Container(
            height: 155,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  kBg.withOpacity(0.85),
                  kBg,
                ],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// AVATAR
          Positioned(
            top: 150 - avatarSize / 1.5,
            child: CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: kCard,
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundImage: userProfile?.profilePicture != null
                    ? NetworkImage(userProfile!.profilePicture!)
                    : null,
                child: userProfile?.profilePicture == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
            ),
          ),
        ],
      ),
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

  Widget _nameSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Text(
            userProfile?.displayName ?? 'Unknown Coach',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text('Coach', style: TextStyle(color: kMuted)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              userProfile?.bio ?? 'No bio available',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'My Teams',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, i) => _teamItem(userTeams[i]),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: userTeams.length,
          ),
        ),
      ],
    );
  }

  Widget _teamItem(TeamsTable team) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
          child: team.logoUrl == null
              ? const Icon(Icons.shield, size: 22)
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: kMuted),
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
