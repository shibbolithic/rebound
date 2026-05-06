import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';

class TeamPlayersView extends StatefulWidget {
  final String teamId;

  const TeamPlayersView({
    super.key,
    required this.teamId,
  });

  @override
  State<TeamPlayersView> createState() => _TeamPlayersViewState();
}

class _TeamPlayersViewState extends State<TeamPlayersView> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  List<UsersTable> players = [];
  Map<String, String> roleMap = {};

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final memberships = await supabase
        .from('team_memberships')
        .select()
        .eq('team_id', widget.teamId);

    if (memberships.isEmpty) {
      setState(() => loading = false);
      return;
    }

    final userIds =
        memberships.map<String>((e) => e['user_id']).toList();

    for (final m in memberships) {
      roleMap[m['user_id']] = m['role_in_team'];
    }

    final usersRes =
        await supabase.from('users').select().inFilter('id', userIds);

    players = usersRes.map<UsersTable>(UsersTable.fromMap).toList();

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Team Players'),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade800,
                        child: Text(
                          p.displayName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              roleMap[p.id] ?? 'player',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
