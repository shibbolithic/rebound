import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../views/create/team/create_team_view.dart';
import 'package:image_picker/image_picker.dart';

class CreateTeamController {
  final SupabaseClient _client = Supabase.instance.client;

  // ---------------- FETCH COACHES ----------------
  Future<List<AppUser2>> fetchCoaches() async {
    final res = await _client
        .from('users')
        .select()
        .eq('role', 'coach');

    return (res as List)
        .map((e) => AppUser2.fromMap(e))
        .toList();
  }

  // ---------------- FETCH ATHLETES ----------------
  Future<List<AppUser2>> fetchAthletes() async {
    final res = await _client
        .from('users')
        .select()
        .eq('role', 'athlete');

    return (res as List)
        .map((e) => AppUser2.fromMap(e))
        .toList();
  }

  // ---------------- UPLOAD TEAM LOGO ----------------
  Future<String?> uploadTeamLogo(File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName =
          'team_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final bytes = await file.readAsBytes();

      await _client.storage.from('team-logos').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      return _client.storage
          .from('team-logos')
          .getPublicUrl(fileName);
    } catch (e) {
      print('❌ LOGO UPLOAD FAILED: $e');
      return null;
    }
  }

Future<String> uploadTeamLogo1({required XFile file}) async {
  final bytes = await file.readAsBytes();
  final ext = file.name.split('.').last;

  // Path INSIDE the bucket (folder-like, name can have hyphens)
  final path = 'logos/${DateTime.now().millisecondsSinceEpoch}.$ext';

  // ✅ Bucket name EXACTLY as in Supabase
  await _client.storage
      .from('team_logos')
      .uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

  // ✅ Same bucket name here
  return _client.storage
      .from('team_logos')
      .getPublicUrl(path);
}



  // ---------------- CREATE TEAM ----------------
  Future<void> createTeam({
  required String name,
  String? motto,
  String? logoUrl,
  required List<AppUser2> coaches,
  required List<AppUser2> members,
}) async {
  try {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 🔹 Insert team
    final team = await _client
        .from('teams')
        .insert({
          'name': name,
          'motto': motto,
          'logo_url': logoUrl,
          'created_by': user.id,
        })
        .select()
        .single();

    final teamId = team['id'];

    // 🔹 Track added users
    final Set<String> addedUserIds = {};

// Determine creator role (coach / athlete)
final String creatorRole =
    user.role == 'coach' ? 'coach' : 'player';

// 🔹 Add creator as coach/athlete
await _client.from('team_memberships').insert({
  'team_id': teamId,
  'user_id': user.id,
  'role_in_team': creatorRole,
});

addedUserIds.add(user.id);

    // 🔹 Add coaches
    for (final coach in coaches) {
      if (addedUserIds.contains(coach.id)) continue;

      await _client.from('team_memberships').insert({
        'team_id': teamId,
        'user_id': coach.id,
        'role_in_team': 'coach',
      });
      addedUserIds.add(coach.id);
    }

    // 🔹 Add members
    for (final member in members) {
      if (addedUserIds.contains(member.id)) continue;

      await _client.from('team_memberships').insert({
        'team_id': teamId,
        'user_id': member.id,
        'role_in_team': 'player',
      });
      addedUserIds.add(member.id);
    }

    print('✅ TEAM CREATED WITHOUT DUPLICATES');

  } catch (e) {
    print('❌ CREATE TEAM FAILED: $e');
    rethrow;
  }
}
}