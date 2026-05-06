//models.dart
/* =======================
   1️⃣ USERS
   ======================= */

class UsersTable {
  final String id;
  final String? username; // nullable
  final String displayName;
  final String email;
  final String? profilePicture;
  final String? coverPicture;
  final String? bio;
  final String role; // athlete | coach | admin
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  UsersTable({
    required this.id,
    this.username, // ❌ remove required
    required this.displayName,
    required this.email,
    this.profilePicture,
    this.coverPicture,
    this.bio,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    required this.isActive,
  });

  factory UsersTable.fromMap(Map<String, dynamic> map) {
    return UsersTable(
      id: map['id'] as String,
      username: map['username'] as String?, // safe cast
      displayName: map['display_name'] as String,
      email: map['email'] as String,
      profilePicture: map['profile_picture'] as String?,
      coverPicture: map['cover_picture'] as String?,
      bio: map['bio'] as String?,
      role: map['role'] as String,
      createdAt: DateTime.parse(map['created_at']),
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'])
          : null,
      isActive: map['is_active'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'email': email,
        'profile_picture': profilePicture,
        'cover_picture': coverPicture,
        'bio': bio,
        'role': role,
        'created_at': createdAt.toIso8601String(),
        'last_login': lastLogin?.toIso8601String(),
        'is_active': isActive,
      };
}

/* =======================
   2️⃣ ATHLETE PROFILES
   ======================= */

class AthleteProfilesTable {
  final String userId;
  final double? heightCm;
  final double? weightKg;
  final int experienceYears;
  final String? position; // PG | SG | SF | PF | C
  final double avgPointsPerGame;
  final double avgReboundsPerGame;
  final double avgAssistsPerGame;
  final DateTime updatedAt;

  AthleteProfilesTable({
    required this.userId,
    this.heightCm,
    this.weightKg,
    required this.experienceYears,
    this.position,
    required this.avgPointsPerGame,
    required this.avgReboundsPerGame,
    required this.avgAssistsPerGame,
    required this.updatedAt,
  });

  factory AthleteProfilesTable.fromMap(Map<String, dynamic> map) {
  return AthleteProfilesTable(
    userId: map['user_id'] as String,

    heightCm: (map['height_cm'] as num?)?.toDouble(),
    weightKg: (map['weight_kg'] as num?)?.toDouble(),

    experienceYears: (map['experience_years'] ?? 0) as int,

    position: map['position'] as String?,

    avgPointsPerGame:
        (map['avg_points_per_game'] as num?)?.toDouble() ?? 0.0,

    avgReboundsPerGame:
        (map['avg_rebounds_per_game'] as num?)?.toDouble() ?? 0.0,

    avgAssistsPerGame:
        (map['avg_assists_per_game'] as num?)?.toDouble() ?? 0.0,

    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : DateTime.now(),
  );
}

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'experience_years': experienceYears,
        'position': position,
        'avg_points_per_game': avgPointsPerGame,
        'avg_rebounds_per_game': avgReboundsPerGame,
        'avg_assists_per_game': avgAssistsPerGame,
        'updated_at': updatedAt.toIso8601String(),
      };
}

/* =======================
   3️⃣ COACH PROFILES
   ======================= */

class CoachProfilesTable {
  final String userId;
  final int yearsExperience;
  final String? specialization;
  final String? certifications;
  final DateTime updatedAt;

  CoachProfilesTable({
    required this.userId,
    required this.yearsExperience,
    this.specialization,
    this.certifications,
    required this.updatedAt,
  });

  factory CoachProfilesTable.fromMap(Map<String, dynamic> map) {
    return CoachProfilesTable(
      userId: map['user_id'],
      yearsExperience: map['years_experience'],
      specialization: map['specialization'],
      certifications: map['certifications'],
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'years_experience': yearsExperience,
        'specialization': specialization,
        'certifications': certifications,
        'updated_at': updatedAt.toIso8601String(),
      };
}

/* =======================
   4️⃣ TEAMS
   ======================= */

class TeamsTable {
  final String id;
  final String name;
  final String? motto;
  final String? logoUrl;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;
  final int? wins;
  final int? losses;

  TeamsTable({
    required this.id,
    required this.name,
    this.motto,
    this.logoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    this.wins,
    this.losses,
  });

  factory TeamsTable.fromMap(Map<String, dynamic> map) {
    return TeamsTable(
      id: map['id'],
      name: map['name'],
      motto: map['motto'],
      logoUrl: map['logo_url'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      isActive: map['is_active'],
      wins: map['wins'],
      losses: map['losses'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'motto': motto,
        'logo_url': logoUrl,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'is_active': isActive,
        'wins': wins,
        'losses': losses,
      };
}

/* =======================
   5️⃣ TEAM MEMBERSHIPS
   ======================= */

class TeamMembershipsTable {
  final String id;
  final String teamId;
  final String userId;
  final String roleInTeam; // player | coach
  final DateTime joinedAt;
  final bool isCaptain;

  TeamMembershipsTable({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.roleInTeam,
    required this.joinedAt,
    required this.isCaptain,
  });

  factory TeamMembershipsTable.fromMap(Map<String, dynamic> map) {
    return TeamMembershipsTable(
      id: map['id'],
      teamId: map['team_id'],
      userId: map['user_id'],
      roleInTeam: map['role_in_team'],
      joinedAt: DateTime.parse(map['joined_at']),
      isCaptain: map['is_captain'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'team_id': teamId,
        'user_id': userId,
        'role_in_team': roleInTeam,
        'joined_at': joinedAt.toIso8601String(),
        'is_captain': isCaptain,
      };
}

/* =======================
   6️⃣ GAMES
   ======================= */

class GamesTable {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime gameDatetime;
  final String? venue;
  final String status; // scheduled | completed | cancelled
  final int? homeScore;
  final int? awayScore;
  final String createdBy;
  final DateTime createdAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final bool isPending;

  GamesTable({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.gameDatetime,
    this.venue,
    required this.status,
    this.homeScore,
    this.awayScore,
    required this.createdBy,
    required this.createdAt,
    this.approvedBy,
    this.approvedAt,
    required this.isPending,
  });

  factory GamesTable.fromMap(Map<String, dynamic> map) {
    return GamesTable(
      id: map['id'],
      homeTeamId: map['home_team_id'],
      awayTeamId: map['away_team_id'],
      gameDatetime: DateTime.parse(map['game_datetime']),
      venue: map['venue'],
      status: map['status'],
      homeScore: map['home_score'] ?? 0,
      awayScore: map['away_score'] ?? 0,
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      approvedBy: map['approved_by'],
      approvedAt:
          map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      isPending: map['is_pending'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'home_team_id': homeTeamId,
        'away_team_id': awayTeamId,
        'game_datetime': gameDatetime.toIso8601String(),
        'venue': venue,
        'status': status,
        'home_score': homeScore,
        'away_score': awayScore,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'is_pending': isPending,
      };
}

/* =======================
   7️⃣ PLAYER GAME STATS
   ======================= */

class PlayerGameStatsTable {
  final String id;
  final String gameId;
  final String teamId;
  final String playerId;
  final int made2;
  final int made3;
  final int madeFt;
  final int missed2;
  final int missed3;
  final int rebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int fouls;
  final int totalPoints;
  final String createdBy;
  final DateTime createdAt;

  PlayerGameStatsTable({
    required this.id,
    required this.gameId,
    required this.teamId,
    required this.playerId,
    required this.made2,
    required this.made3,
    required this.madeFt,
    required this.missed2,
    required this.missed3,
    required this.rebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.fouls,
    required this.totalPoints,
    required this.createdBy,
    required this.createdAt,
  });

  factory PlayerGameStatsTable.fromMap(Map<String, dynamic> map) {
    return PlayerGameStatsTable(
      id: map['id'],
      gameId: map['game_id'],
      teamId: map['team_id'],
      playerId: map['player_id'],
      made2: map['made_2'],
      made3: map['made_3'],
      madeFt: map['made_ft'],
      missed2: map['missed_2'],
      missed3: map['missed_3'],
      rebounds: map['rebounds'],
      assists: map['assists'],
      steals: map['steals'],
      blocks: map['blocks'],
      fouls: map['fouls'],
      totalPoints: map['total_points'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

/* =======================
   4️⃣ COACH APPROVAL
   ======================= */

class CoachApprovalTable {
  final String id;
  final String userId;

  // Submitted details
  final String? specialisation;
  final String? certificationUrl;
  final String? universityName;
  final int? yearOfPassing;
  final String? universityPocName;
  final String? universityPhone;
  final int? yearsExperience;

  // Approval tracking
  final String status; // pending | approved | rejected
  final String? rejectionReason;
  final DateTime? reviewedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  CoachApprovalTable({
    required this.id,
    required this.userId,
    this.specialisation,
    this.certificationUrl,
    this.universityName,
    this.yearOfPassing,
    this.universityPocName,
    this.universityPhone,
    this.yearsExperience,
    required this.status,
    this.rejectionReason,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoachApprovalTable.fromMap(Map<String, dynamic> map) {
    return CoachApprovalTable(
      id: map['id'],
      userId: map['user_id'],
      specialisation: map['specialisation'],
      certificationUrl: map['certification_url'],
      universityName: map['university_name'],
      yearOfPassing: map['year_of_passing'],
      universityPocName: map['university_poc_name'],
      universityPhone: map['university_phone'],
      yearsExperience: map['years_experience'],
      status: map['status'],
      rejectionReason: map['rejection_reason'],
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'specialization': specialisation,
      'certification_url': certificationUrl,
      'university_name': universityName,
      'year_of_passing': yearOfPassing,
      'university_poc_name': universityPocName,
      'university_phone': universityPhone,
      'years_experience': yearsExperience,
      'status': status,
      'rejection_reason': rejectionReason,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
/* =======================
   👁️ VIEW: APPROVED PLAYER STATS
   ======================= */

class ApprovedPlayerStatsView {
  final String playerId;
  final String gameId;
  final int totalPoints;
  final int rebounds;
  final int assists;

  ApprovedPlayerStatsView({
    required this.playerId,
    required this.gameId,
    required this.totalPoints,
    required this.rebounds,
    required this.assists,
  });

  factory ApprovedPlayerStatsView.fromMap(Map<String, dynamic> map) {
    return ApprovedPlayerStatsView(
      playerId: map['player_id'],
      gameId: map['game_id'],
      totalPoints: map['total_points'],
      rebounds: map['rebounds'],
      assists: map['assists'],
    );
  }
}

/* =======================
   📊 MV: PLAYER SEASON STATS
   ======================= */

class MvPlayerSeasonStatsTable {
  final String playerId;
  final int gamesPlayed;
  final int totalPoints;
  final double avgPoints;
  final double avgRebounds;
  final double avgAssists;

  MvPlayerSeasonStatsTable({
    required this.playerId,
    required this.gamesPlayed,
    required this.totalPoints,
    required this.avgPoints,
    required this.avgRebounds,
    required this.avgAssists,
  });

  factory MvPlayerSeasonStatsTable.fromMap(Map<String, dynamic> map) {
    return MvPlayerSeasonStatsTable(
      playerId: map['player_id'],
      gamesPlayed: map['games_played'],
      totalPoints: map['total_points'],
      avgPoints: map['avg_points'].toDouble(),
      avgRebounds: map['avg_rebounds'].toDouble(),
      avgAssists: map['avg_assists'].toDouble(),
    );
  }
}

/* =======================
   📊 MV: TEAM STATS
   ======================= */

class MvTeamStatsTable {
  final String teamId;
  final int gamesPlayed;
  final int totalPoints;
  final double avgPointsPerGame;

  MvTeamStatsTable({
    required this.teamId,
    required this.gamesPlayed,
    required this.totalPoints,
    required this.avgPointsPerGame,
  });

  factory MvTeamStatsTable.fromMap(Map<String, dynamic> map) {
    return MvTeamStatsTable(
      teamId: map['team_id'],
      gamesPlayed: map['games_played'],
      totalPoints: map['total_points'],
      avgPointsPerGame: map['avg_points_per_game'].toDouble(),
    );
  }
}
