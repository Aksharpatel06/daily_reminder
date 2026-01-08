import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

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
    _loadMembers();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'All Members',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No members found", style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: member.isAdmin ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                        style: TextStyle(color: member.isAdmin ? Colors.orange : colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(member.area, style: TextStyle(color: Colors.grey[500])),
                    trailing: member.isAdmin
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                            ),
                            child: const Text(
                              "Admin",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          )
                        : null,
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
              },
            ),
    );
  }
}
