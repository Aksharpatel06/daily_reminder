import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../utils/custom_color.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<UserModel> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final users = await _dbService.getAllUsers();
    setState(() {
      _members = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CustomColor.subTextColor.withValues(alpha: 0.1),
                            border: Border.all(color: CustomColor.subTextColor.withValues(alpha: 0.6)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.arrow_back, color: CustomColor.textColor, size: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Members',
                              style: GoogleFonts.afacad(fontSize: 24, fontWeight: FontWeight.bold, color: CustomColor.textColor),
                            ),
                            Text('Read daily and get’s Swami’s rajipo', style: GoogleFonts.afacad(color: CustomColor.subTextColor, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CustomColor.primaryColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: CustomColor.textColor))
                    : _members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: CustomColor.subTextColor),
                            const SizedBox(height: 16),
                            Text("No members found", style: TextStyle(color: CustomColor.subTextColor)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: CustomColor.secondaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.3), spreadRadius: 5, blurRadius: 10, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: CustomColor.textColor,
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                  style: GoogleFonts.afacad(color: CustomColor.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              title: Text(
                                member.name,
                                style: GoogleFonts.afacad(fontWeight: FontWeight.w400, fontSize: 22, color: CustomColor.textColor),
                              ),
                              subtitle: Text(member.area, style: GoogleFonts.afacad(color: CustomColor.subTextColor)),
                              trailing: member.isAdmin
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: CustomColor.textColor),
                                      ),
                                      child: const Text(
                                        "Admin",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CustomColor.textColor),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
