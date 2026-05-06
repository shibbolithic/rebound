import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rebound/views/create/team/create_team_view.dart';

const kBg = Color(0xFF0B0B0F);
const kCard = Color(0xFF1C1C1E);
const kMuted = Color(0xFF8E8E93);
const kOrange = Color(0xFFFF6B35);
const kText = Colors.white;

class SelectUsersModal extends StatefulWidget {
  final String title;
  final List<AppUser2> users;
  final int max;

  const SelectUsersModal({
    super.key,
    required this.title,
    required this.users,
    required this.max,
  });

  @override
  State<SelectUsersModal> createState() => _SelectUsersModalState();
}

class _SelectUsersModalState extends State<SelectUsersModal> {
  final List<AppUser2> selected = [];
  final TextEditingController searchCtrl = TextEditingController();

  List<AppUser2> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    filteredUsers = List.from(widget.users);
  }

  void _onSearch(String query) {
    setState(() {
      filteredUsers = widget.users
          .where(
            (u) => u.displayName
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: kBg,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ───── TITLE ─────
            Text(
              widget.title,
              style: const TextStyle(
                color: kText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // ───── SEARCH ─────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: _onSearch,
                  cursorColor: kText,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: kMuted),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color: kMuted,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ───── LIST ─────
            Expanded(
              child: ListView.separated(
                itemCount: filteredUsers.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Colors.transparent,
                ),
                itemBuilder: (_, i) {
                  final user = filteredUsers[i];
                  final isSelected = selected.contains(user);

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    leading: CircleAvatar(
                      backgroundColor: kCard,
                      backgroundImage: user.profilePicture != null
                          ? NetworkImage(user.profilePicture!)
                          : null,
                      child: user.profilePicture == null
                          ? Text(
                              user.displayName[0],
                              style: const TextStyle(color: kText),
                            )
                          : null,
                    ),
                    title: Text(
                      user.displayName,
                      style: const TextStyle(
                        color: kText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            selected.remove(user);
                          } else if (selected.length < widget.max) {
                            selected.add(user);
                          }
                        });
                      },
                      activeColor: kOrange,
                      checkColor: Colors.black,
                      side: const BorderSide(
                        color: kMuted,
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ───── DONE BUTTON ─────
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
