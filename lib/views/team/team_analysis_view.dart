import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import 'package:fl_chart/fl_chart.dart';


class TeamAnalysisView extends StatefulWidget {
  final String teamId;

  const TeamAnalysisView({super.key, required this.teamId});

  @override
  State<TeamAnalysisView> createState() => _TeamAnalysisViewState();
}

const kCard = Color(0xFF1C1C1E);

const kOrange = Color(0xFFFF7A18);     // offense
const kLavender = Color(0xFFB18CFF);   // defense
const kMutedGrey = Color(0xFF8E8E93);  // neutral

class _TeamAnalysisViewState extends State<TeamAnalysisView> {
  final supabase = Supabase.instance.client;
  bool loading = true;

  List<GamesTable> games = [];
  List<PlayerGameStatsTable> stats = [];

  /* ======================
     AGGREGATES
     ====================== */

  int wins = 0;
  int losses = 0;
  int draws = 0;

Map<String, String> _playerNames = {};
bool _loadingTopPlayers = false;

  

  double avgPointsFor = 0;
  double avgPointsAgainst = 0;
  double avgPointDiff = 0;



int? _lastTouchedIndex;
DateTime? _lastSnackTime;
bool _efficiencySnackShown = false;

  int bestWinStreak = 0;
  int longestLosingStreak = 0;

  double performanceStability = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    final gameRes = await supabase
        .from('games')
        .select()
        .or(
          'home_team_id.eq.${widget.teamId},away_team_id.eq.${widget.teamId}',
        )
        .eq('status', 'completed')
        .order('game_datetime');

    games = gameRes.map<GamesTable>(GamesTable.fromMap).toList();

    final statRes = await supabase
        .from('player_game_stats')
        .select()
        .eq('team_id', widget.teamId);

    stats =
        statRes.map<PlayerGameStatsTable>(PlayerGameStatsTable.fromMap).toList();

    _calculateOutcomes();
    _calculateStreaks();
    _calculateStability();
    _prepareGraphData(); // 👈 🔥 THIS WAS MISSING


    setState(() => loading = false);
  }

  Future<void> _loadPlayerNames(List<String> playerIds) async {
  if (playerIds.isEmpty) return;

  setState(() => _loadingTopPlayers = true);

  final res = await supabase
      .from('users')
      .select('id, display_name')
      .inFilter('id', playerIds);

  final Map<String, String> nameMap = {
    for (final row in res)
      row['id'] as String: row['display_name'] as String,
  };

  setState(() {
    _playerNames.addAll(nameMap);
    _loadingTopPlayers = false;
  });
}



  /* ======================
     CALCULATIONS
     ====================== */

  void _calculateOutcomes() {
    int scored = 0;
    int conceded = 0;

    for (final g in games) {
      final isHome = g.homeTeamId == widget.teamId;
      final teamScore = isHome ? g.homeScore! : g.awayScore!;
      final oppScore = isHome ? g.awayScore! : g.homeScore!;

      scored += teamScore;
      conceded += oppScore;

      if (teamScore > oppScore) wins++;
      if (teamScore < oppScore) losses++;
      if (teamScore == oppScore) draws++;
    }

    avgPointsFor = games.isEmpty ? 0 : scored / games.length;
    avgPointsAgainst = games.isEmpty ? 0 : conceded / games.length;
    avgPointDiff = avgPointsFor - avgPointsAgainst;
  }

  void _calculateStreaks() {
    int currentWin = 0;
    int currentLoss = 0;

    for (final g in games) {
      final isHome = g.homeTeamId == widget.teamId;
      final teamScore = isHome ? g.homeScore! : g.awayScore!;
      final oppScore = isHome ? g.awayScore! : g.homeScore!;

      if (teamScore > oppScore) {
        currentWin++;
        currentLoss = 0;
        bestWinStreak = max(bestWinStreak, currentWin);
      } else if (teamScore < oppScore) {
        currentLoss++;
        currentWin = 0;
        longestLosingStreak = max(longestLosingStreak, currentLoss);
      }
    }
  }

  void _calculateStability() {
    if (games.length < 2) {
      performanceStability = 100;
      return;
    }

    final diffs = games.map((g) {
      final isHome = g.homeTeamId == widget.teamId;
      final teamScore = isHome ? g.homeScore! : g.awayScore!;
      final oppScore = isHome ? g.awayScore! : g.homeScore!;
      return (teamScore - oppScore).toDouble();
    }).toList();

    final mean =
        diffs.reduce((a, b) => a + b) / diffs.length;

    final variance = diffs
            .map((d) => pow(d - mean, 2))
            .reduce((a, b) => a + b) /
        diffs.length;

    final stdDev = sqrt(variance);

    performanceStability = (100 - stdDev * 3).clamp(0, 100);
  }
  /* ======================
   GRAPH DATA
   ====================== */

List<FlSpot> pointsForSeries = [];
List<FlSpot> pointsAgainstSeries = [];
List<int> winLossTimeline = []; // 1 = win, 0 = loss, -1 = draw

void _prepareGraphData() {
  pointsForSeries.clear();
  pointsAgainstSeries.clear();
  winLossTimeline.clear();

  for (int i = 0; i < games.length; i++) {
    final g = games[i];
    final isHome = g.homeTeamId == widget.teamId;

    final teamScore = isHome ? g.homeScore! : g.awayScore!;
    final oppScore = isHome ? g.awayScore! : g.homeScore!;

    pointsForSeries.add(FlSpot(i.toDouble(), teamScore.toDouble()));
    pointsAgainstSeries.add(FlSpot(i.toDouble(), oppScore.toDouble()));

    if (teamScore > oppScore) winLossTimeline.add(1);
    else if (teamScore < oppScore) winLossTimeline.add(0);
    else winLossTimeline.add(-1);
  }
}


double get avg2ptEfficiency {
  int made = 0;
  int missed = 0;

  for (final s in stats) {
    made += s.made2;
    missed += s.missed2;
  }

  final attempts = made + missed;
  if (attempts == 0) return 0;

  return (made / attempts) * 100;
}

double get avg3ptEfficiency {
  int made = 0;
  int missed = 0;

  for (final s in stats) {
    made += s.made3;
    missed += s.missed3;
  }

  final attempts = made + missed;
  if (attempts == 0) return 0;

  return (made / attempts) * 100;
}


  /* ======================
     UI
     ====================== */

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('Team Analysis'),
      backgroundColor: Colors.black,
      elevation: 0,
    ),
    body: loading
        ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// ======================
              /// KPIs
              /// ======================
              _sectionHeader('KPIs'),
              _summaryGrid(),

              const SizedBox(height: 32),

              /// ======================
              /// TRENDS
              /// ======================
              _sectionHeader('Trends'),
              _pointsLineChart(
                spots: pointsForSeries,
                color: kOrange,
                title: 'Points Scored per Match',
              ),
              _pointsLineChart(
                spots: pointsAgainstSeries,
                color: kLavender,
                title: 'Points Conceded per Match',
              ),
              
              const SizedBox(height: 12),
              _winLossDonut(),
              const SizedBox(height: 12),
              _winLossTimeline(),

              const SizedBox(height: 32),

              /// ======================
              /// EFFICIENCY
              /// ======================
              _sectionHeader('Efficiency & Quality of Play'),
              _efficiencyBar(
                'Avg 2PT Efficiency',
                avg2ptEfficiency,
                kOrange,
              ),
              _efficiencyBar(
                'Avg 3PT Efficiency',
                avg3ptEfficiency,
                kLavender,
              ),

              const SizedBox(height: 32),

              /// ======================
              /// CONTRIBUTION
              /// ======================
              _sectionHeader('Contribution & Impact'),
_topContributorsList(),
            ],
          ),
  );
}


  /* ======================
     SECTIONS
     ====================== */

  Widget _performanceSummary() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Best Win Streak', bestWinStreak.toString()),
          _chip('Longest Losing Streak', longestLosingStreak.toString()),
          _chip(
            'Stability',
            performanceStability.toStringAsFixed(0),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _kpiRow() {
    return Row(
      children: [
        _kpi('Avg Scored', avgPointsFor),
        _kpi('Avg Conceded', avgPointsAgainst),
        _kpi('Avg Diff', avgPointDiff),
      ],
    );
  }

  /* ======================
     SMALL UI
     ====================== */

  Widget _chip(String label, String value, {bool highlight = false}) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.white : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.black : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: highlight ? Colors.black54 : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, double value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _placeholderGraph(String title) {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }
  
  Widget _winLossSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Wins: $wins   Losses: $losses   Draws: $draws',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
  Widget _summaryGrid() {
  final items = [
    _summaryItem(
      label: 'Best Win Streak',
      value: bestWinStreak.toString(),
      icon: Icons.trending_up_rounded,
    ),
    _summaryItem(
      label: 'Losing Streak',
      value: longestLosingStreak.toString(),
      icon: Icons.trending_down_rounded,
    ),
    _summaryItem(
      label: 'Stability',
      value: performanceStability.toStringAsFixed(0),
      icon: Icons.stacked_line_chart_rounded,
    ),
    _summaryItem(
      label: 'Avg Scored',
      value: avgPointsFor.toStringAsFixed(1),
      icon: Icons.sports_basketball_rounded,
    ),
    _summaryItem(
      label: 'Avg Conceded',
      value: avgPointsAgainst.toStringAsFixed(1),
      icon: Icons.shield_outlined,
    ),
    _summaryItem(
      label: 'Avg Diff',
      value: avgPointDiff.toStringAsFixed(1),
      icon: Icons.swap_vert_rounded,
    ),
  ];

  return GridView.count(
    crossAxisCount: 3,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.05,
    children: items,
  );
}
Widget _summaryItem({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.grey.shade300,
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

  Widget _placeholderCard(String title) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  //graphs
Widget _pointsLineChart({
  required List<FlSpot> spots,
  required Color color,
  required String title,
}) {
  if (spots.isEmpty) {
    return const SizedBox.shrink();
  }

  final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

  return Container(
    height: 180,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: (minY - 5).clamp(0, double.infinity),
              maxY: maxY + 5,

              /* ───────── GRID ───────── */
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 5,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.08),
                  strokeWidth: 1,
                ),
              ),

              /* ───────── AXIS LABELS ───────── */
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    reservedSize: 36,
                    getTitlesWidget: (value, _) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 22,
                    getTitlesWidget: (value, _) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),

              /* ───────── BORDER ───────── */
              borderData: FlBorderData(show: false),

              /* ───────── TOUCH ───────── */
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toInt()} pts',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),

              /* ───────── LINE ───────── */
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _winLossTimeline() {
  if (winLossTimeline.isEmpty) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'No match data',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  final List<Widget> bars = [];

  for (final r in winLossTimeline) {
    Color c;
    if (r == 1) {
      c = kOrange;
    } else if (r == 0) {
      c = kLavender;
    } else {
      c = kMutedGrey;
    }

    bars.add(
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  return Container(
    height: 60,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: bars),
  );
}

Widget _winLossDonut() {
  final total = wins + losses + draws;
  if (total == 0) return const SizedBox();

  Widget legendItem(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($value)',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TITLE
        const Text(
          'Win / Loss Distribution',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        /// CHART (NO TOUCH / NO SNACKBAR)
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 42,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(enabled: false),
              sections: [
                PieChartSectionData(
                  value: wins.toDouble(),
                  color: kOrange,
                  title:
                      '${((wins / total) * 100).toStringAsFixed(0)}%',
                  titleStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                ),
                PieChartSectionData(
                  value: losses.toDouble(),
                  color: kLavender,
                  title:
                      '${((losses / total) * 100).toStringAsFixed(0)}%',
                  titleStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                ),
                PieChartSectionData(
                  value: draws.toDouble(),
                  color: kMutedGrey,
                  title:
                      '${((draws / total) * 100).toStringAsFixed(0)}%',
                  titleStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// LEGEND GRID
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [
            legendItem('Wins', wins, kOrange),
            legendItem('Losses', losses, kLavender),
            legendItem('Draws', draws, kMutedGrey),
          ],
        ),
      ],
    ),
  );
}


Widget _efficiencyBar(String label, double pct, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct / 100,
          minHeight: 8,
          backgroundColor: Colors.grey.shade800,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}



Widget _topContributorsList() {
  final byPlayer = <String, int>{};

  for (final s in stats) {
    byPlayer[s.playerId] =
        (byPlayer[s.playerId] ?? 0) + s.totalPoints;
  }

  if (byPlayer.isEmpty) return const SizedBox();

  final topPlayers = byPlayer.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top5 = topPlayers.take(5).toList();
  final topPlayerIds = top5.map((e) => e.key).toList();

  /// 🔹 Load names if missing
  if (!_loadingTopPlayers &&
      topPlayerIds.any((id) => !_playerNames.containsKey(id))) {
    _loadPlayerNames(topPlayerIds);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Top Scorers',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),

      ...top5.map((e) {
        final playerName =
            _playerNames[e.key] ?? 'Loading…';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${e.value} pts',
                style: const TextStyle(
                  color: kOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );
}



}


// Widget _topContribution() {
//   final total = stats.fold(0, (s, e) => s + e.totalPoints);
//   if (total == 0) return const SizedBox();

//   final byPlayer = <String, int>{};
//   for (final s in stats) {
//     byPlayer[s.playerId] =
//         (byPlayer[s.playerId] ?? 0) + s.totalPoints;
//   }

//   final top = byPlayer.values.reduce(max);
//   final pct = (top / total) * 100;

//   return _efficiencyBar(
//     'Top Scorer Contribution',
//     pct,
//     kOrange,
//   );
// }