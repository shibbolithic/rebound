import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:image_picker/image_picker.dart';

class ProfileController {
  final SupabaseClient _client = Supabase.instance.client;

  // =========================
  // FETCH PROFILE (EXISTING)
  // =========================
  Future<Map<String, dynamic>> fetchProfile() async {
    final userId = _client.auth.currentUser!.id;

    final user = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    final athleteProfile = await _client
        .from('athlete_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    final seasonStats = await _client
        .from('mv_player_season_stats')
        .select()
        .eq('player_id', userId)
        .maybeSingle();

    final teams = await _client
        .from('team_memberships')
        .select('teams(*)')
        .eq('user_id', userId);

    final games = await _client
        .from('games')
        .select()
        .order('game_datetime', ascending: false)
        .limit(10);

    return {
      'user': user,
      'athlete': athleteProfile,
      'stats': seasonStats,
      'teams': teams,
      'games': games,
    };
  }

  // =========================
  // SETTINGS: UPDATE USERS
  // =========================
  
  final _picker = ImagePicker();
  
    Future<XFile?> pickImage() async {
  final picker = ImagePicker();
  return await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
}


  Future<String> uploadProfileImage({
  required XFile file,
  required String userId,
  required bool isCover,
}) async {
  final folder = isCover ? 'cover_photos' : 'profile_photos';
  final path = '$folder/$userId.jpg';

  final bytes = await file.readAsBytes();

  await _client.storage.from('profile').uploadBinary(
    path,
    bytes,
    fileOptions: const FileOptions(
      upsert: true,
      contentType: 'image/jpeg',
    ),
  );

  final publicUrl = _client.storage.from('profile').getPublicUrl(path);

  // 👇 cache-busting without changing storage
  return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
}




    Future<void> updateUserCore({
    required String userId,
    String? displayName,
    String? profileUrl,
    String? coverUrl,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};

    if (displayName != null) updates['display_name'] = displayName;
    if (profileUrl != null) updates['profile_picture'] = profileUrl;
    if (coverUrl != null) updates['cover_picture'] = coverUrl;
    if (bio != null) updates['bio'] = bio;

    if (updates.isEmpty) return;

    await _client.from('users').update(updates).eq('id', userId);
  }

  // =========================
  // SETTINGS: ATHLETE PROFILE
  // =========================
  Future<void> upsertAthleteProfile({
  required String userId,
  double? heightCm,
  double? weightKg,
  int? experienceYears,
  String? position,
}) async {
  // 1️⃣ Ensure row exists (NO nullable fields)
  await _client.from('athlete_profiles').upsert({
    'user_id': userId,
    'updated_at': DateTime.now().toIso8601String(),
  });

  // 2️⃣ Partial update (ONLY changed fields)
  final data = <String, dynamic>{
    'updated_at': DateTime.now().toIso8601String(),
  };

  if (heightCm != null) data['height_cm'] = heightCm;
  if (weightKg != null) data['weight_kg'] = weightKg;
  if (experienceYears != null) {
    data['experience_years'] = experienceYears;
  }
  if (position != null) data['position'] = position;

  // If nothing changed, skip DB call
  if (data.length == 1) return;

  await _client
      .from('athlete_profiles')
      .update(data)
      .eq('user_id', userId);
}


  // =========================
  // SETTINGS: COACH PROFILE
  // =========================
  Future<void> upsertCoachProfile({
  required String userId,
  int? yearsExperience,
  String? specialization,
  String? certifications,
}) async {
  // 1️⃣ Ensure row exists
  await _client.from('coach_profiles').upsert({
    'user_id': userId,
    'updated_at': DateTime.now().toIso8601String(),
  });

  // 2️⃣ Partial update
  final data = <String, dynamic>{
    'updated_at': DateTime.now().toIso8601String(),
  };

  if (yearsExperience != null) {
    data['years_experience'] = yearsExperience;
  }
  if (specialization != null) data['specialization'] = specialization;
  if (certifications != null) data['certifications'] = certifications;

  if (data.length == 1) return;

  await _client
      .from('coach_profiles')
      .update(data)
      .eq('user_id', userId);
}

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
