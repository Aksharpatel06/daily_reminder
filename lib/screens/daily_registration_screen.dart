import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reading_record.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../provider/auth_provider.dart';
import '../utils/custom_color.dart';

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
    return Scaffold(
      backgroundColor: CustomColor.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: CustomColor.primaryColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: buildDateFilter()),
                    if (_isLoading) _buildShimmer() else ..._buildAdminList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
                      'Registration',
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
    );
  }

  Widget buildDateFilter() {
    return Column(
      children: [
        GestureDetector(
          onTap: (_isAdmin) ? _selectDate : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CustomColor.textColor.withValues(alpha: 0.9), shape: BoxShape.circle),
            child: Icon(_isAdmin ? Icons.edit_calendar_rounded : Icons.calendar_today_rounded, color: CustomColor.primaryColor, size: 30),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          DateFormat('MMMM dd, yyyy\nEEEE').format(_selectedDate),
          textAlign: TextAlign.center,
          style: GoogleFonts.afacad(fontSize: 22, color: CustomColor.textColor),
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            style: GoogleFonts.afacad(fontSize: 20),
            children: [
              TextSpan(
                text: 'Did you',
                style: GoogleFonts.afacad(fontSize: 16, color: CustomColor.subTextColor),
              ),
              TextSpan(
                text: ' Read ',
                style: GoogleFonts.afacad(fontSize: 16, color: CustomColor.textColor),
              ),
              TextSpan(
                text: 'and get',
                style: GoogleFonts.afacad(fontSize: 16, color: CustomColor.subTextColor),
              ),
              TextSpan(
                text: ' Rajipo ',
                style: GoogleFonts.afacad(fontSize: 16, color: CustomColor.textColor),
              ),
              TextSpan(
                text: 'today?',
                style: GoogleFonts.afacad(fontSize: 16, color: CustomColor.subTextColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
          );
        }, childCount: 3),
      ),
    );
  }

  List<Widget> _buildAdminList() {
    List<Widget> slivers = [];

    // Show the admin's own reading status first
    Widget adminReadingSection = Container();
    if (_userTodayRecord != null) {
      adminReadingSection = Row(
        children: [
          Expanded(
            child: _buildCompactToggle(
              "Vachnamrut",
              _userTodayRecord!.vachnamrut,
              (val) => _submitUserReading(true, val),
              'assets/img/vachanamrut.png',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactToggle(
              "Swamini Vato",
              _userTodayRecord!.swaminiVato,
              (val) => _submitUserReading(false, val),
              'assets/img/swani_vatoo.png',
            ),
          ),
        ],
      );
    }

    if (_adminUserRecords.isEmpty) {
      slivers.add(SliverToBoxAdapter(child: adminReadingSection));
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: CustomColor.subTextColor.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No members found', style: GoogleFonts.afacad(color: CustomColor.subTextColor)),
              ],
            ),
          ),
        ),
      );
      return slivers;
    }

    int total = _adminUserRecords.length;
    int read = _adminUserRecords.where((data) => (data['swaminiVato'] as bool) || (data['vachnamrut'] as bool)).length;
    int notRead = total - read;

    slivers.add(SliverToBoxAdapter(child: adminReadingSection));

    slivers.add(
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                'Member’s Status',
                style: GoogleFonts.afacad(fontSize: 20, fontWeight: FontWeight.w900, color: CustomColor.textColor),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Total", total.toString()),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  _buildStatItem("Read", read.toString()),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  _buildStatItem("Not Read", notRead.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final data = _adminUserRecords[index];
            final UserModel user = data['user'];
            final bool swamini = data['swaminiVato'];
            final bool vachnamrut = data['vachnamrut'];
            final String time = data['time'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: CustomColor.secondaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: CustomColor.primaryColor,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: GoogleFonts.afacad(color: CustomColor.textColor, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  user.name,
                  style: GoogleFonts.afacad(fontWeight: FontWeight.bold, color: CustomColor.textColor),
                ),
                subtitle: Text(time, style: GoogleFonts.afacad(color: CustomColor.subTextColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildStatusIcon(vachnamrut, "V"), const SizedBox(width: 8), _buildStatusIcon(swamini, "S")],
                ),
              ),
            );
          }, childCount: _adminUserRecords.length),
        ),
      ),
    );

    return slivers;
  }

  Widget _buildCompactToggle(String title, bool value, Function(bool) onChanged, String imagePath) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: AlignmentGeometry.topCenter,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.all(12),
              height: 116,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: CustomColor.secondaryColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
                border: Border.all(color: CustomColor.subTextColor, width: 0.2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.afacad(fontSize: 18, fontWeight: FontWeight.w600, color: CustomColor.textColor),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: value,
                      onChanged: onChanged,
                      activeTrackColor: CustomColor.textColor,
                      activeThumbColor: CustomColor.backgroundColor,
                      inactiveTrackColor: CustomColor.subTextColor,
                      inactiveThumbColor: CustomColor.backgroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: -10, left: 0, right: 0, child: Image.asset(imagePath, width: 100, height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.afacad(fontSize: 25, fontWeight: FontWeight.w900, color: CustomColor.textColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.afacad(fontSize: 12, color: CustomColor.subTextColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(bool isRead, String label) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: isRead ? CustomColor.textColor : CustomColor.subTextColor.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: Center(
        child: isRead
            ? const Icon(Icons.check, color: CustomColor.backgroundColor, size: 20)
            : Text(
                label,
                style: GoogleFonts.afacad(color: CustomColor.subTextColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
