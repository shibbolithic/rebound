import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/models.dart';

import '../analysis/analysis_view.dart';

/* ======================
   BRAND & DESIGN CONSTANTS
   ====================== */

const kPrimaryOrange = Color(0xFFFF5116);
const kAccentPurple = Color(0xFF962DFF);
const kAssistBlue = Color(0xFF4F8EF7);
const kReboundGreen = Color(0xFF2ECC71);

const kGridColor = Color(0xFFE5E7EB);

const kTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

const kAxisTextStyle = TextStyle(
  fontSize: 11,
  color: Colors.grey,
);

const kCardRadius = BorderRadius.all(Radius.circular(18));

class PlayerAnalyticsView extends StatefulWidget {
  const PlayerAnalyticsView({super.key});

  @override
  State<PlayerAnalyticsView> createState() => _PlayerAnalyticsViewState();
}

class _PlayerAnalyticsViewState extends State<PlayerAnalyticsView> {
  final supabase = Supabase.instance.client;

  List<PlayerGameStatsTable> gameLogs = [];
  bool isLoading = false;

  DateTime selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime selectedEndDate = DateTime.now();

  bool showMoreHighlights = false;
  bool isDateFilterApplied = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* ======================
     DATA LOADING
     ====================== */

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('player_game_stats')
        .select()
        .eq('player_id', user.id)
        .order('created_at');

    gameLogs =
        (res as List).map((e) => PlayerGameStatsTable.fromMap(e)).toList();

    setState(() => isLoading = false);
  }

  /* ======================
     FILTERED LOGS
     ====================== */

  List<PlayerGameStatsTable> get filteredLogs {
    if (!isDateFilterApplied) return gameLogs;

    return gameLogs.where((log) {
      return log.createdAt
              .isAfter(selectedStartDate.subtract(const Duration(days: 1))) &&
          log.createdAt
              .isBefore(selectedEndDate.add(const Duration(days: 1)));
    }).toList();
  }

  /* ======================
     STATS
     ====================== */

  int get totalPoints =>
      filteredLogs.fold(0, (s, e) => s + e.totalPoints);

  int get totalRebounds =>
      filteredLogs.fold(0, (s, e) => s + e.rebounds);

  int get totalAssists =>
      filteredLogs.fold(0, (s, e) => s + e.assists);

  int get totalSteals =>
      filteredLogs.fold(0, (s, e) => s + e.steals);

  int get totalFouls =>
      filteredLogs.fold(0, (s, e) => s + e.fouls);

  double get avgPoints =>
      filteredLogs.isEmpty ? 0 : totalPoints / filteredLogs.length;

  int _max(int Function(PlayerGameStatsTable) f) =>
      filteredLogs.isEmpty
          ? 0
          : filteredLogs.map(f).reduce((a, b) => a > b ? a : b);

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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _highlights(),
                        const SizedBox(height: 24),
                        _summary(),
                        const SizedBox(height: 24),
                        _chartCard('Points Over Games', _pointsChart()),
                        _chartCard('Rebounds & Assists', _rebAstChart()),
                        _chartCard('Shot Distribution', _shotPie()),
                        _chartCard('Efficiency Score', _efficiencyChart()),
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
            const Text('Player Analytics', style: kTitleStyle),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _pickDateRange,
            ),
          ],
        ),
      );

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: selectedStartDate, end: selectedEndDate),
    );

    if (range != null) {
      setState(() {
        selectedStartDate = range.start;
        selectedEndDate = range.end;
        isDateFilterApplied = true;
      });
    }
  }

  /* ======================
     HIGHLIGHTS
     ====================== */

    Widget _highlights() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
Row(
  children: [
    const Text('Top Highlights', style: kTitleStyle),
    const Spacer(),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalysisView()),
        );
      },
      child: const Text('Show More'),
    ),
  ],
),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _highlightCard('Most Points', _max((e) => e.totalPoints),
                    Icons.local_fire_department),
                _highlightCard('Rebounds', _max((e) => e.rebounds),
                    Icons.sports_basketball),
                _highlightCard(
                    'Assists', _max((e) => e.assists), Icons.group),
                _highlightCard(
                    'Steals', _max((e) => e.steals), Icons.flash_on),
                _highlightCard(
                    'Fouls', _max((e) => e.fouls), Icons.warning),
              ],
            ),
          ),
        ],
      );


    Widget _highlightCard(String title, int value, IconData icon) => Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
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
            Icon(icon, size: 22, color: Colors.deepOrange),
            const Spacer(),
            Text(
              value.toString(),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );


  /* ======================
     SUMMARY
     ====================== */

  Widget _summary() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Summary', style: kTitleStyle),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    setState(() => showMoreHighlights = !showMoreHighlights),
                child:
                    Text(showMoreHighlights ? 'Show Less' : 'Show More'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryCard('Total Points', totalPoints),
              _summaryCard('Avg Points', avgPoints.toStringAsFixed(1)),
              _summaryCard('Rebounds', totalRebounds),
              _summaryCard('Assists', totalAssists),
              if (showMoreHighlights)
                _summaryCard('Steals', totalSteals),
              if (showMoreHighlights)
                _summaryCard('Fouls', totalFouls),
            ],
          ),
        ],
      );

  Widget _summaryCard(String title, dynamic value) => Container(
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
            Text(value.toString(),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      );

  /* ======================
     CHART CARD
     ====================== */

  Widget _chartCard(String title, Widget chart) => Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: kCardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: kTitleStyle),
            const SizedBox(height: 16),
            SizedBox(height: 240, child: chart),
          ],
        ),
      );

  /* ======================
     INTERPRETABLE CHARTS
     ====================== */

  Widget _pointsChart() => LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: kGridColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 10,
                reservedSize: 32,
                getTitlesWidget: (v, _) =>
                    Text(v.toInt().toString(), style: kAxisTextStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) =>
                    Text('G${v.toInt() + 1}', style: kAxisTextStyle),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: kPrimaryOrange,
              barWidth: 3,
              dotData: FlDotData(show: false),
              spots: filteredLogs
                  .asMap()
                  .entries
                  .map((e) =>
                      FlSpot(e.key.toDouble(), e.value.totalPoints.toDouble()))
                  .toList(),
            ),
          ],
        ),
      );

  Widget _rebAstChart() => BarChart(
        BarChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: kGridColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 32,
                getTitlesWidget: (v, _) =>
                    Text(v.toInt().toString(), style: kAxisTextStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) =>
                    Text('G${v.toInt() + 1}', style: kAxisTextStyle),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: filteredLogs.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                    toY: e.value.rebounds.toDouble(),
                    color: kReboundGreen),
                BarChartRodData(
                    toY: e.value.assists.toDouble(),
                    color: kAccentPurple),
              ],
            );
          }).toList(),
        ),
      );

  Widget _shotPie() => Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                      value: filteredLogs
                          .fold(0, (s, e) => s + e.made2)
                          .toDouble(),
                      color: kPrimaryOrange),
                  PieChartSectionData(
                      value: filteredLogs
                          .fold(0, (s, e) => s + e.made3)
                          .toDouble(),
                      color: kAccentPurple),
                  PieChartSectionData(
                      value: filteredLogs
                          .fold(0, (s, e) => s + e.madeFt)
                          .toDouble(),
                      color: kAssistBlue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _legendRow([
            _legendItem('2 Pointers', kPrimaryOrange),
            _legendItem('3 Pointers', kAccentPurple),
            _legendItem('Free Throws', kAssistBlue),
          ]),
        ],
      );

  Widget _efficiencyChart() => LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: kGridColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 10,
                reservedSize: 32,
                getTitlesWidget: (v, _) =>
                    Text(v.toInt().toString(), style: kAxisTextStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) =>
                    Text('G${v.toInt() + 1}', style: kAxisTextStyle),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: kAccentPurple,
              barWidth: 3,
              dotData: FlDotData(show: false),
              spots: filteredLogs.asMap().entries.map((e) {
                final log = e.value;
                final eff = log.totalPoints +
                    log.rebounds +
                    log.assists +
                    log.steals -
                    log.fouls;
                return FlSpot(e.key.toDouble(), eff.toDouble());
              }).toList(),
            ),
          ],
        ),
      );

  /* ======================
     LEGENDS
     ====================== */

  Widget _legendRow(List<Widget> items) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items,
      );

  Widget _legendItem(String text, Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(text,
                style:
                    TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ],
        ),
      );
}
