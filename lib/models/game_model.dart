class GameModel {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime gameDateTime;
  final String venue;
  final String status;
  final bool isPending;

  GameModel({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.gameDateTime,
    required this.venue,
    required this.status,
    required this.isPending,
  });

  factory GameModel.fromMap(Map<String, dynamic> map) {
    return GameModel(
      id: map['id'],
      homeTeamId: map['home_team_id'],
      awayTeamId: map['away_team_id'],
      gameDateTime: DateTime.parse(map['game_datetime']),
      venue: map['venue'],
      status: map['status'],
      isPending: map['is_pending'],
    );
  }
}
