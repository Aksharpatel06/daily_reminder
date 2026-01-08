import '../services/file_helper/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;

import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../provider/auth_provider.dart';
import '../models/reading_record.dart';
import '../models/user_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DatabaseService _dbService;

  bool _isLoading = true;
  bool _isAdmin = false;

  String _filterType = 'Today';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedMemberId;

  List<Map<String, dynamic>> _adminReportData = [];
  Map<String, int> _adminSummary = {'totalEmployees': 0, 'active': 0};

  List<ReadingRecord> _userReportData = [];

  @override
  void initState() {
    super.initState();
    _updateDateRange();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    _dbService = DatabaseService(area: user?.area ?? '');
    _checkRoleAndLoad();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    if (_filterType == 'Today') {
      _startDate = now;
      _endDate = now;
    } else if (_filterType == 'Week') {
      _startDate = now.subtract(const Duration(days: 7));
      _endDate = now;
    } else if (_filterType == 'Month') {
      _startDate = DateTime(now.year, now.month - 1, now.day);
      _endDate = now;
    } else if (_filterType == 'Year') {
      _startDate = DateTime(now.year - 1, now.month, now.day);
      _endDate = now;
    }
  }

  Future<void> _checkRoleAndLoad() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      _isAdmin = user.isAdmin;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    if (_isAdmin) {
      final data = await _dbService.getAllUserReadingsForPeriod(_startDate, _endDate);

      int activeCount = 0;
      for (var d in data) {
        if ((d['totalDaysRead'] as int) > 0) activeCount++;
      }

      final stats = await _dbService.getAdminStats();

      setState(() {
        _adminReportData = data;
        _adminSummary = {'totalEmployees': stats['totalEmployees'] ?? 0, 'active': activeCount};
        _isLoading = false;
      });
    } else {
      final uid = context.read<AuthProvider>().currentUser?.userId;
      if (uid != null) {
        final data = await _dbService.getUserReadingsForPeriod(uid, _startDate, _endDate);
        setState(() {
          _userReportData = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFilterChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _filterType = newValue;
        _updateDateRange();
      });
      _loadData();
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> allUsersData = await _dbService.getAllUserDailyReadings(_startDate, _endDate);

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.showGridlines = true;

      // Generate List of Dates involved
      List<DateTime> dateRange = [];
      DateTime tempDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day);

      while (tempDate.isBefore(end) || tempDate.isAtSameMomentAs(end)) {
        dateRange.add(tempDate);
        tempDate = tempDate.add(const Duration(days: 1));
      }

      // Headers
      int colIndex = 1;
      sheet.getRangeByIndex(1, colIndex).setText('Username');
      sheet.getRangeByIndex(1, colIndex).columnWidth = 20;
      colIndex++;

      // Date Headers
      for (var date in dateRange) {
        String dateHeader = DateFormat('dd-MM').format(date);
        sheet.getRangeByIndex(1, colIndex).setText(dateHeader);
        sheet.getRangeByIndex(1, colIndex).columnWidth = 8;
        colIndex++;
      }

      // Summary Headers
      sheet.getRangeByIndex(1, colIndex).setText('Total Read');
      sheet.getRangeByIndex(1, colIndex).columnWidth = 12;
      colIndex++;
      sheet.getRangeByIndex(1, colIndex).setText('Total Not Read');
      sheet.getRangeByIndex(1, colIndex).columnWidth = 15;
      colIndex++;
      sheet.getRangeByIndex(1, colIndex).setText('Percentage');
      sheet.getRangeByIndex(1, colIndex).columnWidth = 12;

      // Style Headers
      final Range headerRange = sheet.getRangeByIndex(1, 1, 1, colIndex);
      headerRange.cellStyle.fontSize = 10;
      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.hAlign = HAlignType.center;
      headerRange.cellStyle.wrapText = true;

      // Data Rows
      int rowIndex = 2;

      final filteredList = _selectedMemberId == null
          ? allUsersData
          : allUsersData.where((item) => (item['user'] as UserModel).userId == _selectedMemberId).toList();

      for (var item in filteredList) {
        final user = item['user'] as UserModel;
        final Map<String, ReadingRecord> readings = item['readings'];

        int col = 1;
        sheet.getRangeByIndex(rowIndex, col).setText(user.name);
        col++;

        int totalRead = 0;
        int totalNotRead = 0;

        for (var date in dateRange) {
          final dateStr = DateFormat('dd-MM-yyyy').format(date);
          final record = readings[dateStr];

          bool isRead = false;
          String cellText = "";

          if (record != null) {
            if (record.vachnamrut && record.swaminiVato) {
              cellText = "V, S";
              isRead = true;
            } else if (record.vachnamrut) {
              cellText = "V";
              isRead = true;
            } else if (record.swaminiVato) {
              cellText = "S";
              isRead = true;
            }
          }

          if (isRead) {
            totalRead++;
            sheet.getRangeByIndex(rowIndex, col).setText(cellText);
            sheet.getRangeByIndex(rowIndex, col).cellStyle.hAlign = HAlignType.center;
          } else {
            // Check if date is in future
            if (date.isAfter(DateTime.now())) {
              // Future dates - maybe ignore or leave empty?
              // Treating as 'Not Read' strictly based on logic, but usually we don't count future.
              // For now, let's just count them as Not Read if they are within the filtered range.
            }
            totalNotRead++;
          }
          col++;
        }

        double percentage = (totalRead + totalNotRead) > 0 ? (totalRead / (totalRead + totalNotRead)) * 100 : 0.0;

        sheet.getRangeByIndex(rowIndex, col).setNumber(totalRead.toDouble());
        col++;
        sheet.getRangeByIndex(rowIndex, col).setNumber(totalNotRead.toDouble());
        col++;
        sheet.getRangeByIndex(rowIndex, col).setText("${percentage.toStringAsFixed(1)}%");

        rowIndex++;
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final String fileName = 'Matrix_Report_${DateFormat('ddMMyyyy_HHmmss').format(DateTime.now())}.xlsx';
      await FileHelper.saveAndLaunchFile(bytes, fileName);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Soft background
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.black87),
                tooltip: 'Export to Excel',
                onPressed: _exportToExcel,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _isAdmin
          ? _buildAdminView(colorScheme)
          : _buildUserView(colorScheme),
    );
  }

  Widget _buildAdminView(ColorScheme colorScheme) {
    final filteredList = _selectedMemberId == null
        ? _adminReportData
        : _adminReportData.where((item) => (item['user'] as UserModel).userId == _selectedMemberId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Overview",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              _buildModernDropdown(_filterType, ['Today', 'Week', 'Month', 'Year'], (val) => _onFilterChanged(val)),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text("Select member to filter", style: TextStyle(color: Colors.grey[400])),
                value: _selectedMemberId,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text("All Members")),
                  ..._adminReportData.map((item) {
                    final user = item['user'] as UserModel;
                    return DropdownMenuItem<String>(value: user.userId, child: Text(user.name));
                  }).toList(),
                ],
                onChanged: (val) {
                  setState(() => _selectedMemberId = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedMemberId == null) _buildOverallCharts() else _buildIndividualCharts(filteredList.firstOrNull),

          const SizedBox(height: 32),
          const Text("Detailed Logs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          if (filteredList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text("No records found", style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final user = item['user'] as UserModel;
                final bool isActive = (item['totalDaysRead'] as int) > 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: isActive ? const Color(0xFFE0E7FF) : Colors.grey[100],
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(color: isActive ? const Color(0xFF6366F1) : Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(user.area, style: TextStyle(color: Colors.grey[500])),
                    trailing: _buildStatBadge(item['vachnamrutCount'], item['swaminiCount'], item['totalDaysRead'], _filterType == 'Today'),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOverallCharts() {
    double activePercentage = 0;
    if ((_adminSummary['totalEmployees'] ?? 0) > 0) {
      activePercentage = (_adminSummary['active'] ?? 0) / (_adminSummary['totalEmployees']!);
    }
    final inactivePercentage = 1 - activePercentage;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                const Text("Participation Rate", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(color: const Color(0xFF6366F1), value: activePercentage * 100, radius: 25, showTitle: false),
                        PieChartSectionData(color: Colors.grey[200]!, value: inactivePercentage * 100, radius: 20, showTitle: false),
                      ],
                      startDegreeOffset: 270,
                      centerSpaceRadius: 40,
                      sectionsSpace: 4,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "${(activePercentage * 100).toStringAsFixed(0)}% Active",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildMiniStatCard("Total Members", "${_adminSummary['totalEmployees']}", Icons.people_outline, Colors.blue),
              const SizedBox(height: 16),
              _buildMiniStatCard("Active Members", "${_adminSummary['active']}", Icons.check_circle_outline, Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualCharts(Map<String, dynamic>? userData) {
    if (userData == null) return const SizedBox.shrink();

    final vCount = userData['vachnamrutCount'] as int;
    final sCount = userData['swaminiCount'] as int;
    final totalReads = userData['totalDaysRead'] as int;

    final daysInPeriod = _endDate.difference(_startDate).inDays + 1;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Reading Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${((totalReads / daysInPeriod) * 100).toStringAsFixed(0)}% Consistency", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF6366F1),
                          value: vCount.toDouble(),
                          title: "V",
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF10B981),
                          value: sCount.toDouble(),
                          title: "S",
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (vCount == 0 && sCount == 0) PieChartSectionData(color: Colors.grey[200]!, value: 1, showTitle: false, radius: 30),
                      ],
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem("Vachnamrut", vCount, const Color(0xFF6366F1)),
                      const SizedBox(height: 8),
                      _buildLegendItem("Swamini Vato", sCount, const Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      _buildLegendItem("Total Days", totalReads, Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(int vCount, int sCount, int daysRead, bool isToday) {
    if (isToday) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTodayIcon(vCount > 0, "V", const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          _buildTodayIcon(sCount > 0, "S", const Color(0xFF10B981)),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text("$daysRead Days", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text("$vCount", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(width: 8),
            Icon(Icons.menu_book, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text("$sCount", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayIcon(bool active, String label, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? color : Colors.transparent,
        border: Border.all(color: active ? color : Colors.grey[300]!),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: active
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildModernDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          items: items.map((String val) {
            String displayVal = val;
            if (val == 'Today') {
              displayVal = 'Today';
            } else if (val == 'Week')
              displayVal = 'Week';
            else if (val == 'Month')
              displayVal = 'Month';
            else if (val == 'Year')
              displayVal = 'Year';
            return DropdownMenuItem<String>(value: val, child: Text(displayVal));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserView(ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My History",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.grey[800]),
              ),
              _buildModernDropdown(_filterType, ['Today', 'Week', 'Month', 'Year'], (val) => _onFilterChanged(val)),
            ],
          ),
        ),
        Expanded(
          child: _userReportData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("No records found", style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _userReportData.length,
                  itemBuilder: (context, index) {
                    final record = _userReportData[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6), size: 24),
                        ),
                        title: Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTodayIcon(record.vachnamrut, "V", const Color(0xFF6366F1)),
                            const SizedBox(width: 12),
                            _buildTodayIcon(record.swaminiVato, "S", const Color(0xFF10B981)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1, end: 0);
                  },
                ),
        ),
      ],
    );
  }
}
