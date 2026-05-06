import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';

import '../profile/settings/settings_view.dart';

import '../home/game_stats_view.dart';


class AthleteProfileView extends StatefulWidget {
  const AthleteProfileView({super.key});

  @override
  State<AthleteProfileView> createState() => _AthleteProfileViewState();
}

// ======================
// iOS DARK THEME TOKENS
// ======================

const kBg = Color(0xFF0B0B0F);        // App background (true dark)
const kCard = Color(0xFF1C1C1E);      // iOS card
const kMuted = Color(0xFF8E8E93);     // iOS secondary label
const kPrimary = Color(0xFFFF7A1A);   // Your orange (controlled)

class _AthleteProfileViewState extends State<AthleteProfileView> {
  final supabase = Supabase.instance.client;

  UsersTable? userProfile;
  AthleteProfilesTable? athleteProfile;

  List<TeamsTable> userTeams = [];
  List<GamesTable> recentGames = [];

  Map<String, String> teamNames = {};

  Map<String, TeamsTable> teamsMap = {};




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

  Future<void> _loadTeamsForGames(List<GamesTable> games) async {
  final teamIds = <String>{};

  for (final g in games) {
    teamIds.add(g.homeTeamId);
    teamIds.add(g.awayTeamId);
  }

  if (teamIds.isEmpty) return;

  final teamsRes = await supabase
      .from('teams')
      .select()
      .inFilter('id', teamIds.toList());

  final teams = teamsRes
      .map<TeamsTable>((e) => TeamsTable.fromMap(e))
      .toList();

  for (final t in teams) {
    teamsMap[t.id] = t;
  }
}

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authUser = supabase.auth.currentUser;
if (authUser == null) {
  setState(() => isLoading = false);
  return;
}
      final userId = authUser.id;

      /// ---------- USER ----------
      final userRes = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      userProfile = UsersTable.fromMap(userRes);

      /// ---------- ATHLETE PROFILE ----------
      final athleteRes = await supabase
          .from('athlete_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

if (athleteRes != null) {
  athleteProfile = AthleteProfilesTable.fromMap(athleteRes);
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

      if (teamIds.isNotEmpty) {
        final teamsRes = await supabase
            .from('teams')
            .select()
            .inFilter('id', teamIds);

        userTeams =
            teamsRes.map<TeamsTable>((e) => TeamsTable.fromMap(e)).toList();

        for (final team in userTeams) {
          teamNames[team.id] = team.name;
        }
      }

      /// ---------- RECENT GAMES ----------
      final gamesRes = await supabase
          .from('games')
          .select().inFilter('is_pending', ['false'])
          .order('game_datetime', ascending: false)
          .limit(5);

recentGames =
    gamesRes.map<GamesTable>((e) => GamesTable.fromMap(e)).toList();

    await _loadTeamsForGames(recentGames);


    /// ✅ LOAD ALL TEAMS USED IN MATCHES
    await _loadTeamsForGames(recentGames);
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
                          // const SizedBox(height: 0),
                          _nameSection(),
const SizedBox(height: 16),
                          if (athleteProfile != null) _statsSection(),
const SizedBox(height: 16),
                          if (userTeams.isNotEmpty) _teamsSection(),
                          if (recentGames.isNotEmpty) _recentMatchesSection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
        ),

        /// 🔧 SETTINGS BUTTON (Top-Right)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: IconButton(
            icon: const Icon(
              Icons.settings,
              size: 26,
            ),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>  SettingsView(user: userProfile!.toMap()),
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
    height: 150 + avatarSize / 2, // ✅ reserve space
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

        /// AVATAR (NO NEGATIVE CLIP)  
        Positioned(
          top: 150 - avatarSize / 1.5,
          child: CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: kCard,
            child: CircleAvatar(
              radius: avatarSize / 2 ,
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


  Widget _nameSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Column(
        children: [
          Text(
            userProfile?.displayName ?? 'Unknown User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text('Athlete', style: TextStyle(color: kMuted)),
          const SizedBox(height: 6),
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

  Widget _statsSection() {
    final a = athleteProfile!;
    return Column(
      children: [
        Row(
          children: [
            _statItem(a.position ?? '-', 'Position'),
            _statItem('${a.experienceYears}', 'Experience'),
            _statItem(
                a.heightCm != null ? '${a.heightCm!.toStringAsFixed(1)} cm' : '-',
                'Height'),
            _statItem(
                a.weightKg != null ? '${a.weightKg!.toStringAsFixed(1)} kg' : '-',
                'Weight'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
_statItem(
  (a.avgPointsPerGame ?? 0).toStringAsFixed(2),
  'PPG',
),
_statItem(
  (a.avgReboundsPerGame ?? 0).toStringAsFixed(2),
  'RPG',
),
_statItem(
  (a.avgAssistsPerGame ?? 0).toStringAsFixed(2),
  'AST',
),          ],
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

  Widget _teamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('My Teams',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        SizedBox(
  height: 100, // ⬅️ increased height
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

Widget _recentMatchesSection() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Recent Matches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            Spacer(),
            Text('Show More', style: TextStyle(color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        ...recentGames.take(3).map(_matchTile),
      ],
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
          builder: (_) => GameStatsView(gameId: g.id),
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

  Widget _statItem(String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white  )),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: kMuted)),
        ],
      ),
    );
  }
}