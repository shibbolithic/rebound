import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/score approval/approve_stats_view.dart';

// ======================
// DARK iOS TOKENS
// ======================

const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kMuted = Color(0xFF8E8E93);
const kOrange = Color(0xFFFF6B35);
const kText = Colors.white;

class ScoreApprovalListView extends StatefulWidget {
  const ScoreApprovalListView({super.key});

  @override
  State<ScoreApprovalListView> createState() =>
      _ScoreApprovalListViewState();
}

class _ScoreApprovalListViewState extends State<ScoreApprovalListView> {
  final supabase = Supabase.instance.client;

  List games = [];
  List<String> myTeamIds = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  // ==========================
  // FETCH PENDING GAMES
  // ==========================
  Future<void> fetchGames() async {
    final userId = supabase.auth.currentUser!.id;

    // 1️⃣ Teams where user is coach
    final teamRes = await supabase
        .from('team_memberships')
        .select('team_id')
        .eq('user_id', userId)
        .eq('role_in_team', 'coach');

    myTeamIds =
        teamRes.map<String>((e) => e['team_id'] as String).toList();

    if (myTeamIds.isEmpty) {
      setState(() => loading = false);
      return;
    }

    // 2️⃣ Pending games
    final gameRes = await supabase
        .from('games')
        .select('''
          id,
          game_datetime,
          home_team:home_team_id (id, name, logo_url),
          away_team:away_team_id (id, name, logo_url),
          game_approvals (
            team_id,
            approved,
            coach:coach_id (display_name)
          )
        ''')
        .eq('is_pending', true)
        .or(
          'home_team_id.in.(${myTeamIds.join(',')}),away_team_id.in.(${myTeamIds.join(',')})',
        )
        .order('game_datetime', ascending: false);

    setState(() {
      games = gameRes;
      loading = false;
    });
  }

  // ==========================
  // APPROVAL STATE (SAFE)
  // ==========================
  Map<String, dynamic> _resolveApproval(Map game) {
    final List approvals =
        (game['game_approvals'] as List?) ?? [];

    Map? myApproval;
    Map? otherApproval;

    for (final a in approvals) {
      if (myTeamIds.contains(a['team_id'])) {
        myApproval = a;
      } else {
        otherApproval = a;
      }
    }

    return {
      'iApproved': myApproval?['approved'] == true,
      'otherApproved': otherApproval?['approved'] == true,
      'otherCoachName':
          otherApproval?['coach']?['display_name'] ??
              'Other coach',
    };
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Approval Requests',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: kText),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: kOrange),
            )
          : games.isEmpty
              ? const Center(
                  child: Text(
                    'No pending approvals',
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 15,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: games.length,
                  itemBuilder: (_, i) {
                    final g = games[i];
                    final home = g['home_team'];
                    final away = g['away_team'];
                    final approval = _resolveApproval(g);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          _TeamAvatar(team: home),
                          const SizedBox(width: 12),

                          // TEAM NAMES
                          Expanded(
                            child: Text(
                              '${home['name']} vs ${away['name']}',
                              style: const TextStyle(
                                color: kText,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // ACTION
                          if (!approval['iApproved'])
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApproveStatsView(
                                      gameId: g['id'],
                                    ),
                                  ),
                                );
                                fetchGames();
                              },
                              child: const Text(
                                'Approve',
                                style: TextStyle(
                                  color: kOrange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Text(
                              "${approval['otherCoachName']}'s approval pending",
                              style: const TextStyle(
                                color: kMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================
// TEAM AVATAR (LOGO / LETTER)
// ==========================
class _TeamAvatar extends StatelessWidget {
  final Map team;
  const _TeamAvatar({required this.team});

  @override
  Widget build(BuildContext context) {
    final logo = team['logo_url'];
    final name = team['name'] ?? '';

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withOpacity(0.08),
      backgroundImage:
          (logo != null && logo.toString().isNotEmpty)
              ? NetworkImage(logo)
              : null,
      child: (logo == null || logo.toString().isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: kText,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

