import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../core/supabase_client.dart';

// ======================
// DARK THEME TOKENS
// ======================

const kBg = Color(0xFF0B0B0F);        // screen background
const kCard = Color(0xFF1C1C1E);      // cards / surfaces
const kDivider11 = Color(0xFF2C2C2E);
const kMuted = Color(0xFF8E8E93);
const kOrange = Color(0xFFFF6B35);
const kText = Colors.white;

enum StatAction {
  twoPt,
  threePt,
  ft,
  rebound,
  assist,
  foul,
  miss2,
  miss3,
  steal,
}

class EnterStatsView extends StatefulWidget {
  final String gameName;
  final String location;
  final TeamsTable myTeam;
  final TeamsTable opponentTeam;

  const EnterStatsView({
    super.key,
    required this.gameName,
    required this.location,
    required this.myTeam,
    required this.opponentTeam,
  });

  @override
  State<EnterStatsView> createState() => _EnterStatsViewState();
}

class _EnterStatsViewState extends State<EnterStatsView> {
  StatAction? selectedAction;

  int myScore = 0;
  int oppScore = 0;

  // final myPlayers1 = <_PlayerStat>[];
  // final oppPlayers1 = <_PlayerStat>[];

final List<LivePlayerStat> myPlayers = [];
final List<LivePlayerStat> oppPlayers = [];


final List<UndoAction> undoStack = [];

  @override
  void initState() {
    super.initState();
      _loadTeamPlayers(); // mock for now
  }

  void _showGameSavedDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // force user to tap OK
    builder: (_) => AlertDialog(
      title: const Text('Game Saved'),
      content: const Text('The game has been saved successfully.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // close dialog

            /// OPTION A (recommended): Go to TabBar/Home explicitly
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home', // 👈 your TabBar route
              (route) => false,
            );

            /// OPTION B (use ONLY if TabBar is first route)
            // Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}


  Future<void> _saveGame() async {
  try {
    final client = SupabaseConfig.client;
    final userId = client.auth.currentUser!.id;

    /// 1️⃣ INSERT GAME
    final gameRes = await client
        .from('games')
        .insert({
          'home_team_id': widget.myTeam.id,
          'away_team_id': widget.opponentTeam.id,
          'game_datetime': DateTime.now().toIso8601String(),
          'venue': widget.location,
          'status': 'completed', // or 'scheduled' if you want approval later
          'home_score': myScore,
          'away_score': oppScore,
          'created_by': userId,
          'is_pending': true, // set true if coach approval required
        })
        .select()
        .single();

    final String gameId = gameRes['id'];


    /// ======================
    /// 2️⃣ FETCH COACH IDS
    /// ======================
    final coachRes = await client
        .from('team_memberships')
        .select('team_id, user_id')
        .inFilter(
          'team_id',
          [widget.myTeam.id, widget.opponentTeam.id],
        )
        .eq('role_in_team', 'coach');

    String? homeCoachId;
    String? awayCoachId;

    for (final row in coachRes) {
      if (row['team_id'] == widget.myTeam.id) {
        homeCoachId = row['user_id'];
      } else if (row['team_id'] == widget.opponentTeam.id) {
        awayCoachId = row['user_id'];
      }
    }

    if (homeCoachId == null || awayCoachId == null) {
      throw Exception('Coach not found for one or both teams');
    }

        /// ======================
    /// 3️⃣ INSERT APPROVAL ROWS (WITH coach_id ✅)
    /// ======================
    await client.from('game_approvals').insert([
      {
        'game_id': gameId,
        'team_id': widget.myTeam.id,
        'coach_id': homeCoachId,
        'approved': false,
      },
      {
        'game_id': gameId,
        'team_id': widget.opponentTeam.id,
        'coach_id': awayCoachId,
        'approved': false,
      },
    ]);


    /// 4️⃣  BUILD PLAYER GAME STATS ROWS
    final List<Map<String, dynamic>> playerStats = [];

    void addStats(List<LivePlayerStat> players, String teamId) {
      for (final p in players) {
        // skip players with no activity (optional but recommended)
        final hasStats =
            p.pts > 0 ||
            p.reb > 0 ||
            p.ast > 0 ||
            p.stl > 0 ||
            p.foul > 0 ||
            p.fg2Miss > 0 ||
            p.fg3Miss > 0;

        if (!hasStats) continue;

        playerStats.add({
          'game_id': gameId,
          'team_id': teamId,
          'player_id': p.userId,
          'made_2': p.fg2Made,
          'made_3': p.fg3Made,
          'made_ft': p.ftMade,
          'missed_2': p.fg2Miss,
          'missed_3': p.fg3Miss,
          'rebounds': p.reb,
          'assists': p.ast,
          'steals': p.stl,
          'blocks': 0, // add later if you track blocks
          'fouls': p.foul,
          'created_by': userId,
        });
      }
    }

    addStats(myPlayers, widget.myTeam.id);
    addStats(oppPlayers, widget.opponentTeam.id);

    /// 5️⃣  INSERT PLAYER STATS
    if (playerStats.isNotEmpty) {
      await client.from('player_game_stats').upsert(
      playerStats,
      onConflict: 'game_id,player_id',
    );

    }

    /// 6️⃣  SUCCESS UI
    if (!mounted) return;
    
     _showGameSavedDialog();
 // or popUntil home
  } catch (e) {
    debugPrint('SAVE GAME ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save game: $e')),
    );
  }
}


Future<void> _loadTeamPlayers() async {
  final myRes = await SupabaseConfig.client
      .from('team_memberships')
      .select('user_id, users!inner(display_name, role)')
      .eq('team_id', widget.myTeam.id)
      .eq('users.role', 'athlete');

  final oppRes = await SupabaseConfig.client
      .from('team_memberships')
      .select('user_id, users!inner(display_name, role)')
      .eq('team_id', widget.opponentTeam.id)
      .eq('users.role', 'athlete');

  setState(() {
    myPlayers.clear();
    oppPlayers.clear();

    for (final m in myRes) {
      myPlayers.add(
        LivePlayerStat(
          userId: m['user_id'],
          name: m['users']['display_name'],
        ),
      );
    }

    for (final m in oppRes) {
      oppPlayers.add(
        LivePlayerStat(
          userId: m['user_id'],
          name: m['users']['display_name'],
        ),
      );
    }
  });
}


  // void _seedPlayers() {
  //   myPlayers.addAll(List.generate(5, (i) => _PlayerStat('Player ${i + 1}')));
  //   oppPlayers.addAll(List.generate(5, (i) => _PlayerStat('Player ${i + 1}')));
  // }

void _applyAction(LivePlayerStat p, bool isMyTeam) {
  if (selectedAction == null) return;

  setState(() {
    switch (selectedAction!) {
      case StatAction.twoPt:
        p.pts += 2;
        p.fg2Made++;
        isMyTeam ? myScore += 2 : oppScore += 2;
        break;

      case StatAction.threePt:
        p.pts += 3;
        p.fg3Made++;
        isMyTeam ? myScore += 3 : oppScore += 3;
        break;

      case StatAction.ft:
        p.pts += 1;
        p.ftMade++;
        isMyTeam ? myScore += 1 : oppScore += 1;
        break;

      case StatAction.rebound:
        p.reb++;
        break;

      case StatAction.assist:
        p.ast++;
        break;

      case StatAction.steal:
        p.stl++;
        break;

      case StatAction.foul:
        p.foul++;
        break;

      case StatAction.miss2:
        p.fg2Miss++;
        break;

      case StatAction.miss3:
        p.fg3Miss++;
        break;
    }

    undoStack.add(UndoAction(p, selectedAction!, isMyTeam));
  });
}


void _undo() {
  if (undoStack.isEmpty) return;

  final last = undoStack.removeLast();
  final p = last.player;

  setState(() {
    switch (last.action) {
      case StatAction.twoPt:
        p.pts -= 2;
        p.fg2Made--;
        last.isMyTeam ? myScore -= 2 : oppScore -= 2;
        break;

      case StatAction.threePt:
        p.pts -= 3;
        p.fg3Made--;
        last.isMyTeam ? myScore -= 3 : oppScore -= 3;
        break;

      case StatAction.ft:
        p.pts -= 1;
        p.ftMade--;
        last.isMyTeam ? myScore -= 1 : oppScore -= 1;
        break;

      case StatAction.rebound:
        p.reb--;
        break;

      case StatAction.assist:
        p.ast--;
        break;

      case StatAction.steal:
        p.stl--;
        break;

      case StatAction.foul:
        p.foul--;
        break;

      case StatAction.miss2:
        p.fg2Miss--;
        break;

      case StatAction.miss3:
        p.fg3Miss--;
        break;
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30,),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Game', style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _scoreHeader(),
          const SizedBox(height: 12),
          _actionGrid(),
          _undoButton(),
          const SizedBox(height: 8),
          _segmentedContent(),
          _saveButton(),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _scoreHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _teamScore(widget.myTeam.name, myScore),
          const Spacer(),
          const Text('VS', style: TextStyle(fontSize: 18, color: kMuted,)),
          const Spacer(),
          _teamScore(widget.opponentTeam.name, oppScore),
        ],
      ),
    );
  }

  Widget _teamScore(String name, int score) {
    return Column(
      children: [
CircleAvatar(
  radius: 24,
  backgroundColor: kCard,
  child: Text(
    name[0],
    style: const TextStyle(color: Colors.white),
  ),
),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  // ==================stats tab =================
  int _teamSum(List<LivePlayerStat> players, int Function(LivePlayerStat) f) {
  return players.fold(0, (s, p) => s + f(p));
}


  // ================= ACTION GRID =================

  Widget _actionGrid() {
    final actions = {
      '+2 POINTER': StatAction.twoPt,
      '+3 POINTER': StatAction.threePt,
      'FREE THROW': StatAction.ft,
      'REBOUND': StatAction.rebound,
      'ASSIST': StatAction.assist,
      'FOUL': StatAction.foul,
      '2PT FG MISS': StatAction.miss2,
      '3PT FG MISS': StatAction.miss3,
      'STEAL': StatAction.steal,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
        physics: const NeverScrollableScrollPhysics(),
        children: actions.entries.map((e) {
          final selected = selectedAction == e.value;
          return GestureDetector(
            onTap: () => setState(() => selectedAction = e.value),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? kOrange : kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDivider11),
              ),
              child: Center(
                child: Text(
                  e.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: kText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _undoButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: GestureDetector(
          onTap: _undo,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: kOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'UNDO',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ================= SEGMENTS =================

  Widget _segmentedContent() {
    return Expanded(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
  indicator: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
  ),
  labelColor: Colors.white,          // ✅ selected team name
  unselectedLabelColor: Colors.white70, // ✅ unselected still visible
  tabs: [
    Tab(text: widget.myTeam.name),
    Tab(text: widget.opponentTeam.name),
    const Tab(text: 'Stats'),
  ],
),

            Expanded(
              child: TabBarView(
                children: [
                  _playerList(myPlayers, true),
                  _playerList(oppPlayers, false),
                  _statsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerList(List<LivePlayerStat> players, bool isMyTeam) {
  return Column(
    children: [
      _playerHeaderRow(),
      Expanded(
        child: ListView.builder(
          itemCount: players.length,
          itemBuilder: (_, i) {
            final player = players[i]; // ✅ DEFINE IT

            return GestureDetector(
              onTap: selectedAction == null
                  ? null
                  : () => _applyAction(player, isMyTeam),
              child: Container(
  decoration: BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
  ),
  
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: Text(
          player.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
                    _stat(player.reb),
                    _stat(player.ast),
                    _stat(player.stl),
                    _stat(player.foul),
                    _stat(player.pts),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}


  Widget _playerHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: const [
          Expanded(child: Text(
  'Player',
  style: TextStyle(color: kMuted),
),
),
          Text('REB', style: TextStyle(fontSize: 11, color: kMuted)),
          SizedBox(width: 12),
          Text('AST', style: TextStyle(fontSize: 11,  color: kMuted)),
          SizedBox(width: 12),
          Text('STL', style: TextStyle(fontSize: 11,  color: kMuted)),
          SizedBox(width: 12),
          Text('FOUL', style: TextStyle(fontSize: 11,  color: kMuted)),
          SizedBox(width: 12),
          Text('PTS', style: TextStyle(fontSize: 11,  color: kMuted)),
        ],
      ),
    );
  }

Widget _stat(int v) => SizedBox(
  width: 36,
  child: Text(
    v.toString(),
    textAlign: TextAlign.center,
    style: const TextStyle(color: Colors.white),
  ),
);

  // ================= STATS =================

Widget _statsView() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _statsRow(
          '2PT Made',
          _teamSum(myPlayers, (p) => p.fg2Made),
          _teamSum(oppPlayers, (p) => p.fg2Made),
        ),
        _statsRow(
          '3PT Made',
          _teamSum(myPlayers, (p) => p.fg3Made),
          _teamSum(oppPlayers, (p) => p.fg3Made),
        ),
        _statsRow(
          'Free Throws',
          _teamSum(myPlayers, (p) => p.ftMade),
          _teamSum(oppPlayers, (p) => p.ftMade),
        ),
        _statsRow(
          'Rebounds',
          _teamSum(myPlayers, (p) => p.reb),
          _teamSum(oppPlayers, (p) => p.reb),
        ),
        _statsRow(
          'Assists',
          _teamSum(myPlayers, (p) => p.ast),
          _teamSum(oppPlayers, (p) => p.ast),
        ),
        _statsRow(
          'Steals',
          _teamSum(myPlayers, (p) => p.stl),
          _teamSum(oppPlayers, (p) => p.stl),
        ),
        _statsRow(
          'Fouls',
          _teamSum(myPlayers, (p) => p.foul),
          _teamSum(oppPlayers, (p) => p.foul),
        ),
      ],
    ),
  );
}



  Widget _statsRow(String label, int left, int right) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            left.toString(),
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            right.toString(),
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}


  // int _sum(List<_PlayerStat> list, String key) {
  //   return list.fold(0, (sum, p) {
  //     switch (key) {
  //       case 'reb':
  //         return sum + p.reb;
  //       case 'ast':
  //         return sum + p.ast;
  //       case 'stl':
  //         return sum + p.stl;
  //       case 'foul':
  //         return sum + p.foul;
  //       default:
  //         return sum;
  //     }
  //   });
  // }

Widget _saveButton() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saveGame, // ✅ HERE
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text('SAVE', style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}

}

// ================= MODELS =================

// class _PlayerStat {
//   final String name;
//   int pts = 0, reb = 0, ast = 0, stl = 0, foul = 0;

//   _PlayerStat(this.name);

//   _UndoAction? apply(StatAction a) {
//     switch (a) {
//       case StatAction.twoPt:
//         pts += 2;
//         return _UndoAction(this, 2);
//       case StatAction.threePt:
//         pts += 3;
//         return _UndoAction(this, 3);
//       case StatAction.ft:
//         pts += 1;
//         return _UndoAction(this, 1);
//       case StatAction.rebound:
//         reb++;
//         break;
//       case StatAction.assist:
//         ast++;
//         break;
//       case StatAction.steal:
//         stl++;
//         break;
//       case StatAction.foul:
//         foul++;
//         break;
//       case StatAction.miss2:
//       case StatAction.miss3:
//         break;
//     }
//     return _UndoAction(this, 0);
//   }
// }

class UndoAction {
  final LivePlayerStat player;
  final StatAction action;
  final bool isMyTeam;

  UndoAction(this.player, this.action, this.isMyTeam);
}


class LivePlayerStat {
  final String userId;
  final String name;

  int pts = 0;
  int reb = 0;
  int ast = 0;
  int stl = 0;
  int foul = 0;

  int fg2Made = 0;
  int fg3Made = 0;
  int ftMade = 0;

  int fg2Miss = 0;
  int fg3Miss = 0;

  LivePlayerStat({
    required this.userId,
    required this.name,
  });
}

