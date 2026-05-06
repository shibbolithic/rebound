import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';

// ======================
// DARK iOS TOKENS
// ======================
const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kMuted = Color(0xFF8E8E93);
const kOrange = Color(0xFFFF6B35);
const kText = Colors.white;

class GameStatsView extends StatefulWidget {
  final String gameId;

  const GameStatsView({super.key, required this.gameId});

  @override
  State<GameStatsView> createState() => _GameStatsViewState();
}

class _GameStatsViewState extends State<GameStatsView> {
  final supabase = Supabase.instance.client;

  GamesTable? game;
  TeamsTable? homeTeam;
  TeamsTable? awayTeam;

  List<PlayerGameStatsTable> homePlayers = [];
  List<PlayerGameStatsTable> awayPlayers = [];
  Map<String, UsersTable> usersMap = {};

  int selectedTab = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGameStats();
  }

  Future<void> _loadGameStats() async {
    final gameRes = await supabase
        .from('games')
        .select()
        .eq('id', widget.gameId)
        .single();

    game = GamesTable.fromMap(gameRes);

    final teamsRes = await supabase
        .from('teams')
        .select()
        .inFilter('id', [game!.homeTeamId, game!.awayTeamId]);

    for (final t in teamsRes) {
      final team = TeamsTable.fromMap(t);
      if (team.id == game!.homeTeamId) homeTeam = team;
      if (team.id == game!.awayTeamId) awayTeam = team;
    }

    final statsRes = await supabase
        .from('player_game_stats')
        .select()
        .eq('game_id', widget.gameId);

    for (final r in statsRes) {
      final stat = PlayerGameStatsTable.fromMap(r);
      stat.teamId == game!.homeTeamId
          ? homePlayers.add(stat)
          : awayPlayers.add(stat);
    }

    final userIds = {
      ...homePlayers.map((e) => e.playerId),
      ...awayPlayers.map((e) => e.playerId),
    }.toList();

    if (userIds.isNotEmpty) {
      final usersRes =
          await supabase.from('users').select().inFilter('id', userIds);

      for (final u in usersRes) {
        final user = UsersTable.fromMap(u);
        usersMap[user.id] = user;
      }
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: CircularProgressIndicator(color: kOrange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: const BackButton(color: kText),
        centerTitle: true,
        title: Text(
          selectedTab == 2 ? 'Game Stats' : 'Player Stats',
          style: const TextStyle(
            color: kText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _scoreHeader(),
          const SizedBox(height: 12),
          _iosSegmentedControl(),
          const SizedBox(height: 12),
          Expanded(child: _tabContent()),
        ],
      ),
    );
  }

  // ================= SCORE HEADER =================

  Widget _scoreHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _teamHeader(homeTeam!, game!.homeScore ?? 0),
          const Text(
            'VS',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kMuted,
            ),
          ),
          _teamHeader(awayTeam!, game!.awayScore ?? 0),
        ],
      ),
    );
  }

  Widget _teamHeader(TeamsTable team, int score) {
  final hasLogo =
      team.logoUrl != null && team.logoUrl!.trim().isNotEmpty;

  return Column(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: kCard,
        backgroundImage: hasLogo ? NetworkImage(team.logoUrl!) : null,
        child: !hasLogo
            ? Text(
                team.name.isNotEmpty
                    ? team.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
      ),
      const SizedBox(height: 6),
      Text(
        '$score',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: kText,
        ),
      ),
      Text(
        team.name,
        style: const TextStyle(
          fontSize: 12,
          color: kMuted,
        ),
      ),
    ],
  );
}


  // ================= iOS SEGMENTED =================

  Widget _iosSegmentedControl() {
    final labels = [homeTeam!.name, awayTeam!.name, 'Stats'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: List.generate(3, (index) {
            final active = selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? kBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? kText : kMuted,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ================= CONTENT =================

  Widget _tabContent() {
    if (selectedTab == 0) return _playerTable(homePlayers);
    if (selectedTab == 1) return _playerTable(awayPlayers);
    return _teamStats();
  }

  // ================= PLAYER TABLE =================

  Widget _playerTable(List<PlayerGameStatsTable> players) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tableHeader(),
        const SizedBox(height: 8),
        ...players.map(_playerRow),
      ],
    );
  }

  Widget _tableHeader() {
    return Row(
      children: const [
        Expanded(flex: 3, child: Text('PLAYER', style: _headerStyle)),
        Expanded(child: Text('REB', style: _headerStyle)),
        Expanded(child: Text('AST', style: _headerStyle)),
              Expanded(child: Text('STL', style: _headerStyle)), // 👈 ADDED
        Expanded(child: Text('FLS', style: _headerStyle)),
        Expanded(child: Text('PTS', style: _headerStyle)),
      ],
    );
  }

Widget _playerRow(PlayerGameStatsTable s) {
  final user = usersMap[s.playerId];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            user?.displayName ?? '',
            style: const TextStyle(color: kText),
          ),
        ),
        Expanded(child: Text('${s.rebounds}', style: const TextStyle(color: kText))),
        Expanded(child: Text('${s.assists}', style: const TextStyle(color: kText))),
        Expanded(child: Text('${s.steals}', style: const TextStyle(color: kText))), // 👈 ADDED
        Expanded(child: Text('${s.fouls}', style: const TextStyle(color: kText))),
        Expanded(
          child: Text(
            '${s.totalPoints}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: kOrange,
            ),
          ),
        ),
      ],
    ),
  );
}

  // ================= TEAM STATS =================

  Widget _teamStats() {
    int sum(List<PlayerGameStatsTable> l, int Function(PlayerGameStatsTable) f) =>
        l.fold(0, (a, b) => a + f(b));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statRow(sum(homePlayers, (e) => e.made2 + e.made3),
            'Field Goals', sum(awayPlayers, (e) => e.made2 + e.made3)),
        _statRow(sum(homePlayers, (e) => e.madeFt), 'Free Throws',
            sum(awayPlayers, (e) => e.madeFt)),
        _statRow(sum(homePlayers, (e) => e.made3), '3 Pointers',
            sum(awayPlayers, (e) => e.made3)),
        const Divider(color: kCard, height: 32),
        _statRow(sum(homePlayers, (e) => e.rebounds), 'Rebounds',
            sum(awayPlayers, (e) => e.rebounds)),
        _statRow(sum(homePlayers, (e) => e.assists), 'Assists',
            sum(awayPlayers, (e) => e.assists)),
        _statRow(sum(homePlayers, (e) => e.fouls), 'Fouls',
            sum(awayPlayers, (e) => e.fouls)),
        _statRow(sum(homePlayers, (e) => e.steals), 'Steals',
            sum(awayPlayers, (e) => e.steals)),
      ],
    );
  }

  Widget _statRow(int left, String label, int right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$left',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
          ),
          Expanded(
            child: Text(
              '$right',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: kMuted,
);
