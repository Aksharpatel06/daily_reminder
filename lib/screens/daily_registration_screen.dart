import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reading_record.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../provider/auth_provider.dart';

class DailyRegistrationScreen extends StatefulWidget {
  const DailyRegistrationScreen({super.key});

  @override
  State<DailyRegistrationScreen> createState() => _DailyRegistrationScreenState();
}

class _DailyRegistrationScreenState extends State<DailyRegistrationScreen> {
  late DatabaseService _dbService;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isAdmin = false;

  ReadingRecord? _userTodayRecord;

  List<Map<String, dynamic>> _adminUserRecords = [];

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    _dbService = DatabaseService(area: user?.area ?? '');
    _checkRoleAndLoad();
  }

  Future<void> _checkRoleAndLoad() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      _isAdmin = user.isAdmin;
    }

    // if (_isAdmin) {
    await _loadAdminData();
    // } else {
    //   _selectedDate = DateTime.now();
    // }
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final uid = context.read<AuthProvider>().currentUser?.userId;
    final user = context.read<AuthProvider>().currentUser;

    if (uid != null && user != null) {
      // Ensure records exist from createdAt to Today
      await _dbService.ensurePastRecords(uid, user.createdAt);

      final record = await _dbService.getUserReadingFromDate(uid, DateTime.now());
      setState(() {
        _userTodayRecord = record ?? ReadingRecord(date: DateFormat('dd-MM-yyyy').format(DateTime.now()), timestamp: DateTime.now());

        if (record == null) {
          debugPrint('Record was null, auto-uploading default state');
          _dbService.updateDailyRead(uid, _userTodayRecord!);
        }
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final records = await _dbService.getAllUserReadings(_selectedDate);
    setState(() {
      _adminUserRecords = records;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    if (!_isAdmin) return;

    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadAdminData();
    }
  }

  Future<void> _submitUserReading(bool isVachnamrut, bool value) async {
    final uid = context.read<AuthProvider>().currentUser?.userId;
    if (uid == null) return;

    final newRecord = _userTodayRecord!.copyWith(
      vachnamrut: isVachnamrut ? value : _userTodayRecord!.vachnamrut,
      swaminiVato: !isVachnamrut ? value : _userTodayRecord!.swaminiVato,
      timestamp: DateTime.now(),
    );

    setState(() {
      _userTodayRecord = newRecord;
    });

    await _dbService.updateDailyRead(uid, newRecord);

    await _loadAdminData();

    if (mounted) {
      toastification.show(
        context: context,
        title: const Text('Saved'),
        description: const Text('Your reading has been recorded.'),
        type: ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Registration', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildHeader(colorScheme),
          Expanded(child: _isLoading ? _buildShimmer() : _buildAdminList(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer.withValues(alpha: 0.5), colorScheme.secondaryContainer.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAdmin ? 'Selected Date (Filter)' : 'Today\'s Date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_isAdmin)
            IconButton(
              onPressed: _selectDate,
              icon: Icon(Icons.edit_calendar_rounded, color: colorScheme.primary),
              style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.9), padding: const EdgeInsets.all(12)),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }

  Widget _buildAdminList(ColorScheme colorScheme) {
    // Show the admin's own reading status first
    Widget adminReadingSection = Container();
    if (_userTodayRecord != null) {
      adminReadingSection = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              "Your Daily Reading",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactToggle(
                    "Vachnamrut",
                    _userTodayRecord!.vachnamrut,
                    (val) => _submitUserReading(true, val),
                    Icons.book_rounded,
                    const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactToggle(
                    "Swamini Vato",
                    _userTodayRecord!.swaminiVato,
                    (val) => _submitUserReading(false, val),
                    Icons.menu_book_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_adminUserRecords.isEmpty) {
      return Column(
        children: [
          adminReadingSection,
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No members found'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    int total = _adminUserRecords.length;
    int read = _adminUserRecords.where((data) => (data['swaminiVato'] as bool) || (data['vachnamrut'] as bool)).length;
    int notRead = total - read;

    return Column(
      children: [
        adminReadingSection,
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Total", total.toString(), Colors.blue),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem("Read", read.toString(), Colors.green),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem("Not Read", notRead.toString(), Colors.orange),
            ],
          ),
        ).animate().slideY(begin: -0.2, end: 0, duration: 400.ms),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _adminUserRecords.length,
            itemBuilder: (context, index) {
              final data = _adminUserRecords[index];
              final UserModel user = data['user'];
              final bool swamini = data['swaminiVato'];
              final bool vachnamrut = data['vachnamrut'];
              final String time = data['time'] ?? '';
              final bool isRead = swamini || vachnamrut;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
                  border: isRead ? Border.all(color: Colors.green.withValues(alpha: 0.3)) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isRead ? const Color(0xFFE0F2F1) : colorScheme.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(color: isRead ? Colors.teal : colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(time),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIcon(vachnamrut, "V", const Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      _buildStatusIcon(swamini, "S", const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (index * 30).ms).slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactToggle(String title, bool value, Function(bool) onChanged, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
        border: value ? Border.all(color: color, width: 1.5) : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Transform.scale(
            scale: 0.8,
            child: Switch(value: value, onChanged: onChanged, activeColor: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(bool isRead, String label, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: isRead ? color : Colors.grey[200], shape: BoxShape.circle),
      child: Center(
        child: isRead
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
