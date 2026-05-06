import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rebound/views/create/create_modal.dart';
import 'package:rebound/views/home/coach/coach_home_tab_view.dart';
import 'package:rebound/views/home/home_view.dart';
import 'package:rebound/views/profile/profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/models.dart';
import 'enter_stats_view.dart';

const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kOrange = Color(0xFFFF6B35);
const kMuted = Color(0xFF8E8E93);



class CreateGameView extends StatefulWidget {
  const CreateGameView({super.key});

  @override
  State<CreateGameView> createState() => _CreateGameViewState();
}

class _CreateGameViewState extends State<CreateGameView> {
  final _client = Supabase.instance.client;

  final TextEditingController gameNameCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();

  List<TeamsTable> myTeams = [];
  TeamsTable? selectedTeam;

  TeamsTable? opponentTeam;
  List<TeamMembershipsTable> opponentMembers = [];
  List<TeamMembershipsTable> myTeamMembers = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTeams();
  }

  @override
  void dispose() {
    gameNameCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMyTeams() async {
    final userId = _client.auth.currentUser!.id;

    final res = await _client
        .from('team_memberships')
        .select('teams(*)')
        .eq('user_id', userId);

    myTeams = (res as List)
        .map((e) => TeamsTable.fromMap(e['teams']))
        .toList();

    setState(() => loading = false);
  }

  Future<void> _openOpponentSelector() async {
    if (selectedTeam == null) return;

    final res = await showModalBottomSheet<TeamsTable>(
      backgroundColor: kBg,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _OpponentTeamModal(
        excludeTeamId: selectedTeam!.id,
      ),
    );

    if (res != null) {
      final opponentRes = await _client
          .from('team_memberships')
          .select()
          .eq('team_id', res.id);

      final myRes = await _client
          .from('team_memberships')
          .select()
          .eq('team_id', selectedTeam!.id);

      setState(() {
        opponentTeam = res;
        opponentMembers = opponentRes
            .map<TeamMembershipsTable>(
                (e) => TeamMembershipsTable.fromMap(e))
            .toList();
        myTeamMembers = myRes
            .map<TeamMembershipsTable>(
                (e) => TeamMembershipsTable.fromMap(e))
            .toList();
      });
    }
  }

  bool get isValid =>
      gameNameCtrl.text.isNotEmpty &&
      locationCtrl.text.isNotEmpty &&
      selectedTeam != null &&
      opponentTeam != null;

  Future<void> _createGame() async {
    final myIds = myTeamMembers.map((e) => e.userId).toSet();
    final opponentIds = opponentMembers.map((e) => e.userId).toSet();

    final intersectingIds = myIds.intersection(opponentIds);

    if (intersectingIds.isNotEmpty) {
      final users = await _client
          .from('users')
          .select('display_name')
          .inFilter('id', intersectingIds.toList());

      final names =
          users.map((e) => e['display_name'] as String).join(', ');

      _showOverlapAlert(names);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnterStatsView(
          gameName: gameNameCtrl.text.trim(),
          location: locationCtrl.text.trim(),
          myTeam: selectedTeam!,
          opponentTeam: opponentTeam!,
        ),
      ),
    );
  }

  void _showOverlapAlert(String names) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Invalid Teams', style: TextStyle(color: Colors.white),),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$names are a part of both selected teams.\n Please update the team selection to continue.', style: const TextStyle(color: kMuted),
          ),
          
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(

        automaticallyImplyLeading: false,
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30,),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Game', style: TextStyle(color: Colors.white),),
        // leading: const BackButton(),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputCard(),
                  const SizedBox(height: 24),

                  const Text('Select Your Team',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 12),
                  _myTeamsList(),

                  const SizedBox(height: 24),
                  const Text('Select Opponent Team',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 12),
                  _opponentSection(),

                  const SizedBox(height: 32),
                  _createButton(),
                ],
              ),
            ),
    );
  }

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _textField(Icons.sports_basketball, 'Game Name', gameNameCtrl, ),
          const Divider(color: kDivider, height: 0.6),
          _textField(Icons.location_on_outlined, 'Location', locationCtrl),
        ],
      ),
    );
  }

  Widget _textField(
      IconData icon, String hint, TextEditingController ctrl) {
    return TextField(
  controller: ctrl,
  style: const TextStyle(color: Colors.white),
  cursorColor: kOrange,
  decoration: InputDecoration(
    fillColor: kCard,
    icon: Icon(icon, color: kMuted),
    hintText: hint,
    hintStyle: const TextStyle(color: kMuted),
    border: InputBorder.none,
  ),
  onChanged: (_) => setState(() {}),
);
  }

  Widget _myTeamsList() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: myTeams.length,
        itemBuilder: (_, i) {
          final team = myTeams[i];
          final selected = selectedTeam?.id == team.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTeam = team;
                opponentTeam = null;
                opponentMembers.clear();
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        selected ? kOrange : kDivider,
                    backgroundImage:
                        team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
                    child: team.logoUrl == null
                        ? Text(team.name[0])
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(team.name,
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _opponentSection() {
    if (opponentTeam == null) {
      return GestureDetector(
        onTap: selectedTeam == null ? null : _openOpponentSelector,
        child: Column(
          children: const [
            CircleAvatar(
              radius: 26,
              backgroundColor: kDivider,
              child: Icon(Icons.add, color: Colors.white),
            ),
            SizedBox(height: 6),
            Text('Add Team', style: TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      );
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundImage: opponentTeam!.logoUrl != null
              ? NetworkImage(opponentTeam!.logoUrl!)
              : null,
          child: opponentTeam!.logoUrl == null
              ? Text(opponentTeam!.name[0])
              : null,
        ),
        const SizedBox(height: 6),
        Text(opponentTeam!.name,   style: const TextStyle(color: Colors.white),
),
      ],
    );
  }

  Widget _createButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isValid ? _createGame : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isValid ? kOrange : kDivider,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Create',
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}

class _OpponentTeamModal extends StatelessWidget {
  final String excludeTeamId;
  final _client = Supabase.instance.client;

  _OpponentTeamModal({required this.excludeTeamId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _client
          .from('teams')
          .select()
          .eq('is_active', true)
          .neq('id', excludeTeamId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final teams = (snapshot.data as List)
            .map((e) => TeamsTable.fromMap(e))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: teams.length,
            itemBuilder: (_, i) {
              final team = teams[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
                  child:
                      team.logoUrl == null ? Text(team.name[0]) : null,
                ),
                title: Text(team.name, style: const TextStyle(color: Colors.white),),
                onTap: () => Navigator.pop(context, team),
              );
            },
          ),
        );
      },
    );
  }
}
