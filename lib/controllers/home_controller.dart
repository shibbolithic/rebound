import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class HomeController {
  final _supabase = Supabase.instance.client;

  Future<UsersTable> fetchUser(String userId) async {
    final res = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return UsersTable.fromMap(res);
  }

  Future<MvPlayerSeasonStatsTable> fetchSeasonStats(String userId) async {
    final res = await _supabase
        .from('mv_player_season_stats')
        .select()
        .eq('player_id', userId)
        .single();
    return MvPlayerSeasonStatsTable.fromMap(res);
  }

  Future<List<GamesTable>> fetchRecentGames(String userId) async {
    final res = await _supabase
        .from('games')
        .select()
        .or('home_team_id.eq.$userId,away_team_id.eq.$userId')
        .eq('status', 'completed')
        .order('game_datetime', ascending: false)
        .limit(3);

    return (res as List).map((e) => GamesTable.fromMap(e)).toList();
  }

  Future<Map<String, double>> fetchShootingEfficiency(String userId) async {
    final res = await _supabase
        .from('player_game_stats')
        .select('made_2, missed_2, made_3, missed_3, made_ft')
        .eq('player_id', userId);

    int m2 = 0, x2 = 0, m3 = 0, x3 = 0, ft = 0;

    for (final r in res) {
  m2 += (r['made_2'] as num?)?.toInt() ?? 0;
  x2 += (r['missed_2'] as num?)?.toInt() ?? 0;
  m3 += (r['made_3'] as num?)?.toInt() ?? 0;
  x3 += (r['missed_3'] as num?)?.toInt() ?? 0;
  ft += (r['made_ft'] as num?)?.toInt() ?? 0;
    }

    return {
      '2pt': m2 / (m2 + x2 == 0 ? 1 : m2 + x2),
      '3pt': m3 / (m3 + x3 == 0 ? 1 : m3 + x3),
      'ft': ft / (ft == 0 ? 1 : ft),
    };
  }
}
