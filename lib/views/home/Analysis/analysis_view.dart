import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/models.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/models.dart';

/* ======================
   DESIGN / BRAND CONSTANTS
   ====================== */

const kPrimaryOrange = Color(0xFFFF5116);
const kAccentPurple = Color(0xFF962DFF);
const kReboundGreen = Color(0xFF2ECC71);
const kAssistBlue = Color(0xFF4F8EF7);

const kCardRadius = BorderRadius.all(Radius.circular(18));

const kTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

const kLabelStyle = TextStyle(
  fontSize: 13,
  color: Colors.grey,
);

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final supabase = Supabase.instance.client;

  List<PlayerGameStatsTable> logs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* ======================
     DATA LOADING
     ====================== */

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('player_game_stats')
        .select()
        .eq('player_id', user.id)
        .order('created_at');

    logs = (res as List)
        .map((e) => PlayerGameStatsTable.fromMap(e))
        .toList();

    setState(() => loading = false);
  }

  /* ======================
     HELPERS
     ====================== */
  
  double _stdDev(List<int> values) {
  if (values.isEmpty) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance = values
          .map((v) => (v - mean) * (v - mean))
          .reduce((a, b) => a + b) /
      values.length;
  return sqrt(variance);
}

String _consistencyLabel(double std, double avg) {
  if (avg == 0) return 'N/A';
  final ratio = std / avg;
  if (ratio < 0.3) return 'Very Consistent';
  if (ratio < 0.6) return 'Moderately Consistent';
  return 'Inconsistent';
}


  PlayerGameStatsTable? _maxBy(int Function(PlayerGameStatsTable) f) {
    if (logs.isEmpty) return null;
    return logs.reduce((a, b) => f(a) > f(b) ? a : b);
  }

  PlayerGameStatsTable? _minBy(int Function(PlayerGameStatsTable) f) {
    if (logs.isEmpty) return null;
    return logs.reduce((a, b) => f(a) < f(b) ? a : b);
  }

  double _avg(int Function(PlayerGameStatsTable) f) =>
      logs.isEmpty ? 0 : logs.map(f).reduce((a, b) => a + b) / logs.length;

  /* ======================
     UI
     ====================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _performanceStability(),
    const SizedBox(height: 24),
    _roleProfile(),
    const SizedBox(height: 24),
    _bestWorstGames(),
    const SizedBox(height: 24),
    _impactVsUsage(),
  ],
),

                  ),
          ),
        ],
      ),
    );
  }

  /* ======================
     HEADER
     ====================== */

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text('Performance Analysis', style: kTitleStyle),
          ],
        ),
      );

  /* ======================
     EXPANDED HIGHLIGHTS
     ====================== */

  Widget _expandedHighlights() {
    final bestPts = _maxBy((e) => e.totalPoints);
    final bestAst = _maxBy((e) => e.assists);
    final bestReb = _maxBy((e) => e.rebounds);
    final bestEff = _maxBy((e) =>
        e.totalPoints + e.rebounds + e.assists + e.steals - e.fouls);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Performances', style: kTitleStyle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _highlightCard(
              'Highest Scoring Game',
              '${bestPts?.totalPoints ?? 0} pts',
              kPrimaryOrange,
            ),
            _highlightCard(
              'Best Assist Game',
              '${bestAst?.assists ?? 0} ast',
              kAccentPurple,
            ),
            _highlightCard(
              'Best Rebound Game',
              '${bestReb?.rebounds ?? 0} reb',
              kReboundGreen,
            ),
            _highlightCard(
              'Best Efficiency',
              '${bestEff == null ? 0 : bestEff.totalPoints + bestEff.rebounds + bestEff.assists + bestEff.steals - bestEff.fouls}',
              kAssistBlue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _highlightCard(String title, String value, Color color) => Container(
        width: MediaQuery.of(context).size.width / 2 - 24,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: kCardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 16),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: kLabelStyle),
          ],
        ),
      );

  /* ======================
     CONSISTENCY
     ====================== */

  Widget _consistencySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Consistency Overview', style: kTitleStyle),
          const SizedBox(height: 12),
          _consistencyRow('Points', _avg((e) => e.totalPoints)),
          _consistencyRow('Rebounds', _avg((e) => e.rebounds)),
          _consistencyRow('Assists', _avg((e) => e.assists)),
        ],
      );

  Widget _consistencyRow(String title, double avg) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: kCardRadius,
        ),
        child: Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(avg.toStringAsFixed(1),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  /* ======================
     BEST VS WORST
     ====================== */

  Widget _bestWorstGames() {
    final best = _maxBy((e) => e.totalPoints);
    final worst = _minBy((e) => e.totalPoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Best vs Worst Game', style: kTitleStyle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _gameCard('Best Game', best)),
            const SizedBox(width: 12),
            Expanded(child: _gameCard('Worst Game', worst)),
          ],
        ),
      ],
    );
  }

  Widget _gameCard(String title, PlayerGameStatsTable? log) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: kCardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _statRow('PTS', log?.totalPoints ?? 0),
            _statRow('REB', log?.rebounds ?? 0),
            _statRow('AST', log?.assists ?? 0),
            _statRow('STL', log?.steals ?? 0),
            _statRow('FOUL', log?.fouls ?? 0),
          ],
        ),
      );

  Widget _statRow(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label, style: kLabelStyle),
            const Spacer(),
            Text(value.toString(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

      Widget _performanceStability() {
  final points = logs.map((e) => e.totalPoints).toList();
  final rebounds = logs.map((e) => e.rebounds).toList();
  final assists = logs.map((e) => e.assists).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Performance Stability', style: kTitleStyle),
      const SizedBox(height: 12),
      _stabilityRow('Points', points),
      _stabilityRow('Rebounds', rebounds),
      _stabilityRow('Assists', assists),
    ],
  );
}

Widget _stabilityRow(String title, List<int> values) {
  final avg =
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  final std = _stdDev(values);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: kCardRadius,
    ),
    child: Row(
      children: [
        Icon(
          _stabilityIcon(title),
          size: 20,
          color: _stabilityColor(title),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Avg ${avg.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _consistencyLabel(std, avg.toDouble()),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _roleProfile() {
  final totalPts = logs.fold(0, (s, e) => s + e.totalPoints);
  final totalReb = logs.fold(0, (s, e) => s + e.rebounds);
  final totalAst = logs.fold(0, (s, e) => s + e.assists);
  final totalStl = logs.fold(0, (s, e) => s + e.steals);

  final total = totalPts + totalReb + totalAst + totalStl;
  if (total == 0) return const SizedBox();

  double pct(int v) => (v / total) * 100;

  String role;
  if (pct(totalPts) > 40) {
    role = 'Primary Scorer';
  } else if (pct(totalAst) > 30) {
    role = 'Playmaker';
  } else if (pct(totalReb) > 30) {
    role = 'Rebound Specialist';
  } else {
    role = 'Two-Way Player';
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Role Profile', style: kTitleStyle),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: kCardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          children: [
            _roleRow('Scoring', pct(totalPts), kPrimaryOrange),
            _roleRow('Assisting', pct(totalAst), kAccentPurple),
            _roleRow('Rebounding', pct(totalReb), kReboundGreen),
            _roleRow('Defense', pct(totalStl), kAssistBlue),
            const Divider(height: 24),
            Row(
              children: [
                Icon(_finalRoleIcon(role), color: kPrimaryOrange),
                const SizedBox(width: 8),
                Text(
                  role,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _roleRow(String label, double pct, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(_roleIcon(label), size: 18, color: color),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: LinearProgressIndicator(
            value: pct / 100,
            color: color,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}


Widget _impactVsUsage() {
  if (logs.isEmpty) return const SizedBox();

  final avgPts =
      logs.map((e) => e.totalPoints).reduce((a, b) => a + b) / logs.length;

  final lowScoring = logs.where((e) => e.totalPoints < avgPts).toList();
  final highScoring = logs.where((e) => e.totalPoints >= avgPts).toList();

  double impact(List<PlayerGameStatsTable> list) {
    if (list.isEmpty) return 0;
    return list
            .map((e) =>
                e.totalPoints +
                e.rebounds +
                e.assists +
                e.steals -
                e.fouls)
            .reduce((a, b) => a + b) /
        list.length;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Impact Score', style: kTitleStyle),
      const SizedBox(height: 12),
      _impactRow('Low-Scoring Games', impact(lowScoring)),
      _impactRow('High-Scoring Games', impact(highScoring)),
    ],
  );
}

Widget _impactRow(String label, double value) {
  final isHigh = label.contains('High');

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: kCardRadius,
    ),
    child: Row(
      children: [
        Icon(
          isHigh ? Icons.trending_up : Icons.trending_down,
          color: isHigh ? kReboundGreen : Colors.redAccent,
        ),
        const SizedBox(width: 10),
        Text(label),
        const Spacer(),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    ),
  );
}


  /* ======================
     EFFICIENCY BREAKDOWN
     ====================== */

  Widget _efficiencyBreakdown() {
    final totalPts = logs.fold(0, (s, e) => s + e.totalPoints);
    final totalReb = logs.fold(0, (s, e) => s + e.rebounds);
    final totalAst = logs.fold(0, (s, e) => s + e.assists);

    final sum = totalPts + totalReb + totalAst;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Efficiency Contribution', style: kTitleStyle),
        const SizedBox(height: 12),
        _effRow('Scoring', totalPts, sum, kPrimaryOrange),
        _effRow('Rebounding', totalReb, sum, kReboundGreen),
        _effRow('Assisting', totalAst, sum, kAccentPurple),
      ],
    );
  }

  Widget _effRow(
    String title,
    int value,
    int total,
    Color color,
  ) {
    final pct = total == 0 ? 0 : (value / total);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: kCardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pct.toDouble(),
            color: color,
            backgroundColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  IconData _stabilityIcon(String title) {
  switch (title) {
    case 'Points':
      return Icons.sports_basketball;
    case 'Rebounds':
      return Icons.trending_up;
    case 'Assists':
      return Icons.call_split;
    default:
      return Icons.bar_chart;
  }
}

Color _stabilityColor(String title) {
  switch (title) {
    case 'Points':
      return kPrimaryOrange;
    case 'Rebounds':
      return kReboundGreen;
    case 'Assists':
      return kAssistBlue;
    default:
      return Colors.grey;
  }
}
IconData _roleIcon(String label) {
  switch (label) {
    case 'Scoring':
      return Icons.sports_basketball;
    case 'Assisting':
      return Icons.call_split;
    case 'Rebounding':
      return Icons.trending_up;
    case 'Defense':
      return Icons.shield;
    default:
      return Icons.person;
  }
}

IconData _finalRoleIcon(String role) {
  switch (role) {
    case 'Primary Scorer':
      return Icons.local_fire_department;
    case 'Playmaker':
      return Icons.hub;
    case 'Rebound Specialist':
      return Icons.height;
    default:
      return Icons.sync_alt;
  }
}

}
