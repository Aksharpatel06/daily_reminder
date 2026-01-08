import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'daily_registration_screen.dart';
import 'reports_screen.dart';
import 'members_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primaryContainer.withValues(alpha: 0.3), colorScheme.surface, colorScheme.secondaryContainer.withValues(alpha: 0.2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.menu_book_rounded, color: colorScheme.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Reading',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Register and track your reading',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (user != null && user.isAdmin) ...[
                      _buildMenuCard(context, 'Members', 'View all members', Icons.people_rounded, const Color(0xFF6366F1), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MembersScreen()));
                      }).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 16),
                    ],
                    _buildMenuCard(
                      context,
                      'Daily Registration',
                      'Register daily reading',
                      Icons.calendar_today_rounded,
                      const Color(0xFF10B981),
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyRegistrationScreen()));
                      },
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      'Reports',
                      'View weekly, monthly, and yearly reports',
                      Icons.bar_chart_rounded,
                      const Color(0xFFF59E0B),
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                      },
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
