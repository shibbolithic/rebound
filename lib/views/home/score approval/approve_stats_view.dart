import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ======================
// DARK iOS TOKENS
// ======================
const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kMuted = Color(0xFF8E8E93);
const kOrange = Color(0xFFFF6B35);
const kText = Colors.white;

class ApproveStatsView extends StatefulWidget {
  final String gameId;
  const ApproveStatsView({super.key, required this.gameId});

  @override
  State<ApproveStatsView> createState() => _ApproveStatsViewState();
}

class _ApproveStatsViewState extends State<ApproveStatsView> {
  int selectedTab = 0;
  bool loading = true;

  late Map game;
  List<Map<String, dynamic>> homePlayers = [];
  List<Map<String, dynamic>> awayPlayers = [];

  String? coachTeamId;
  Map<String, Map<String, int>> overallStats = {};

  @override
  void initState() {
    super.initState();
    _fetchGameData();
  }

  // ======================
  // FETCH GAME DATA
  // ======================
Future<void> _fetchGameData() async {
  try {
    final supabase = Supabase.instance.client;
    overallStats = {};
    
    final gameRes = await supabase
        .from('games')
        .select('''
        id,
        home_score,
        away_score,
        home_team:home_team_id (id, name, logo_url),
        away_team:away_team_id (id, name, logo_url)
      ''')
        .eq('id', widget.gameId)
        .single();

    final homeTeamId = gameRes['home_team']['id'];
    final awayTeamId = gameRes['away_team']['id'];

    final members = await supabase
        .from('team_memberships')
        .select('team_id, user:users (id, display_name)')
        .eq('role_in_team', 'player')
        .or('team_id.eq.$homeTeamId,team_id.eq.$awayTeamId');

    final stats = await supabase
        .from('player_game_stats')
        .select()
        .eq('game_id', widget.gameId);

    final statMap = {for (final s in stats) s['player_id']: s};

    List<Map<String, dynamic>> buildTeam(String teamId) {
      return members
          .where((m) => m['team_id'] == teamId)
          .map((m) {
        final stat = statMap[m['user']['id']] ?? {};
        return {
          'name': m['user']['display_name'] ?? '—',
          'reb': stat['rebounds'] ?? 0,
          'ast': stat['assists'] ?? 0,
          'stl': stat['steals'] ?? 0,
          'foul': stat['fouls'] ?? 0,
          'pts': stat['total_points'] ?? 0,
          'made2': stat['made_2'] ?? 0,
          'made3': stat['made_3'] ?? 0,
          'ft': stat['made_ft'] ?? 0,
        };
      }).toList();
    }

    homePlayers = buildTeam(homeTeamId);
    awayPlayers = buildTeam(awayTeamId);
    overallStats = _calculateOverall(homePlayers, awayPlayers);

      // Find coach's team
    final userId = supabase.auth.currentUser!.id;
    final teamRes = await supabase
        .from('team_memberships')
        .select('team_id, role_in_team')
        .eq('user_id', userId)
        .or('team_id.eq.$homeTeamId,team_id.eq.$awayTeamId')
        .single();
    coachTeamId = teamRes['role_in_team'] == 'coach' ? teamRes['team_id'] : null;

    setState(() {
      game = gameRes;
      loading = false;
    });

  } catch (e) {
    print("ERROR FETCHING GAME DATA: $e");
    setState(() => loading = false);
  }
}

  // ======================
  // CALCULATE TOTALS
  // ======================
  Map<String, Map<String, int>> _calculateOverall(
      List home, List away) {
    int sum(List l, String k) =>
        l.fold(0, (s, e) => s + (e[k] as int));

    return {
      '2PT': {'home': sum(home, 'made2'), 'away': sum(away, 'made2')},
      '3PT': {'home': sum(home, 'made3'), 'away': sum(away, 'made3')},
      'FT': {'home': sum(home, 'ft'), 'away': sum(away, 'ft')},
      'REB': {'home': sum(home, 'reb'), 'away': sum(away, 'reb')},
      'AST': {'home': sum(home, 'ast'), 'away': sum(away, 'ast')},
      'STL': {'home': sum(home, 'stl'), 'away': sum(away, 'stl')},
      'FOUL': {'home': sum(home, 'foul'), 'away': sum(away, 'foul')},
    };
  }

  // ======================
  // APPROVE / REJECT
  // ======================


  Future<void> _approve() async {
    final supabase = Supabase.instance.client;
    final coachId = supabase.auth.currentUser!.id;

    print("------------------------------");
    print(coachId);
    print("------------------------------");

     // 1️⃣ Find coach's team in this game

    await supabase.from('game_approvals').upsert({
      'game_id': widget.gameId,
      'team_id': coachTeamId,
      'approved': true,
      'approved_at': DateTime.now().toIso8601String(),
      'coach_id': coachId,
    }, onConflict: 'game_id,team_id');

    final approvals = await supabase
        .from('game_approvals')
        .select()
        .eq('game_id', widget.gameId)
        .eq('approved', true);

    if ((approvals as List).length == 2) {
      await supabase.from('games').update({
        'is_pending': false,
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.gameId);
    }

    Navigator.pop(context);
  }

  Future<void> _reject() async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('game_approvals')
        .update({
          'approved': false,
          'approved_at': null,
          'coach_id': null,
        })
        .eq('game_id', widget.gameId);

    await supabase.from('games').update({
      'is_pending': true,
      'approved_at': null,
    }).eq('id', widget.gameId);

    Navigator.pop(context);
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kOrange)),
      );
    }

    final home = game['home_team'];
    final away = game['away_team'];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text('Approve Game', style: TextStyle(color: kText)),
        iconTheme: const IconThemeData(color: kText),
      ),
      body: Column(
        children: [
          _header(home, away),
          _tabs(home['name'], away['name']),
          Expanded(child: _content()),
          _actions(),
        ],
      ),
    );
  }

  Widget _header(Map h, Map a) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _team(h, game['home_score'])),
          const Text('VS',
              style: TextStyle(color: kMuted, fontSize: 16)),
          Expanded(child: _team(a, game['away_score'])),
        ],
      ),
    );
  }

  Widget _team(Map t, int score) {
    final name = t['name'] ?? '';
    final logo = t['logo_url'];

    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: kCard,
          backgroundImage:
              logo != null && logo.toString().isNotEmpty
                  ? NetworkImage(logo)
                  : null,
          child: logo == null
              ? Text(name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: kText, fontSize: 20))
              : null,
        ),
        const SizedBox(height: 6),
        Text('$score',
            style: const TextStyle(
                color: kText,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(name,
            style: const TextStyle(color: kMuted)),
      ],
    );
  }

  Widget _tabs(String h, String a) {
    final labels = [h, a, 'Stats'];
    return Container(
      //color: kCard,
      child: Row(
        children: List.generate(3, (i) {
          final active = selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(labels[i],
                        style: TextStyle(
                          color: active ? kOrange : kMuted,
                          fontWeight:
                              active ? FontWeight.w600 : null,
                        )),
                    if (active)
                      Container(
                          margin: const EdgeInsets.only(top: 6),
                          height: 2,
                          width: 24,
                          color: kOrange),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _content() {
    if (selectedTab == 2) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: overallStats.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                    child: Text('${e.value['home']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kText))),
                Expanded(
                    flex: 2,
                    child: Text(e.key,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kMuted))),
                Expanded(
                    child: Text('${e.value['away']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kText))),
              ],
            ),
          );
        }).toList(),
      );
    }

    final players =
        selectedTab == 0 ? homePlayers : awayPlayers;

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        _statHeader(),
        ...players.map(_playerRow),
      ],
    );
  }

  Widget _statHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text('Players', textAlign: TextAlign.left, style: TextStyle(color: kMuted))),
          Expanded(flex: 3, child: SizedBox()),
          Expanded(child: Text('REB', textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
          Expanded(child: Text('AST', textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
          Expanded(child: Text('STL', textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
          Expanded(child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: kMuted))),
        ],
      ),
    );
  }

  Widget _playerRow(Map p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(p['name'], style: const TextStyle(color: kText))),
          Expanded(child: Text('${p['reb']}', textAlign: TextAlign.center, style: const TextStyle(color: kText))),
          Expanded(child: Text('${p['ast']}', textAlign: TextAlign.center, style: const TextStyle(color: kText))),
          Expanded(child: Text('${p['stl']}', textAlign: TextAlign.center, style: const TextStyle(color: kText))),
          Expanded(child: Text('${p['pts']}', textAlign: TextAlign.center, style: const TextStyle(color: kText))),
        ],
      ),
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kText,
                side: const BorderSide(color: kMuted),
              ),
              onPressed: _reject,
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: kText,
              ),
              onPressed: _approve,
              child: const Text('Approve'),
            ),
          ),
        ],
      ),
    );
  }
}
