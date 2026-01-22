import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../provider/daily_provider.dart';
import '../utils/custom_color.dart';
import 'daily_registration_screen.dart';
import 'reports_screen.dart';
import 'members_screen.dart';
import 'sign_in_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadCurrentUser();
      context.read<DailyProvider>().fetchDailyImages();
    });
  }

  String _convertDriveLink(String url) {
    if (url.contains('drive.google.com') && url.contains('/view')) {
      final idMatch = RegExp(r'/d/([^/]+)/').firstMatch(url);
      if (idMatch != null) {
        final id = idMatch.group(1);
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
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
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CustomColor.subTextColor.withValues(alpha: 0.1),
                            border: Border.all(color: CustomColor.subTextColor.withValues(alpha: 0.6)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.menu_book_rounded, color: CustomColor.textColor, size: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Reading',
                              style: GoogleFonts.afacad(fontSize: 24, fontWeight: FontWeight.bold, color: CustomColor.textColor),
                            ),
                            Text('Register and track your reading', style: GoogleFonts.afacad(color: CustomColor.subTextColor, fontSize: 16)),
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            spacing: 15,
                            children: [
                              Image.asset('assets/img/vachanamrut.png', width: 150),
                              Text(
                                'Vachanamrut',
                                style: GoogleFonts.afacad(fontSize: 22, fontWeight: FontWeight.bold, color: CustomColor.textColor),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Column(
                            spacing: 15,
                            children: [
                              Image.asset('assets/img/swani_vatoo.png', width: 150),
                              Text(
                                'Swamini Vato',
                                style: GoogleFonts.afacad(fontSize: 22, fontWeight: FontWeight.bold, color: CustomColor.textColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Consumer<DailyProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                        }
                        if (provider.dailyImages.isNotEmpty) {
                          return Container(
                            constraints: BoxConstraints(maxHeight: 203),
                            margin: const EdgeInsets.symmetric(vertical: 20.0),
                            child: PageView.builder(
                              controller: PageController(viewportFraction: 0.9),
                              itemCount: provider.dailyImages.length,
                              itemBuilder: (context, index) {
                                final imageUrl = _convertDriveLink(provider.dailyImages[index]);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        return const SizedBox(height: 20);
                      },
                    ),
                    SizedBox(height: 10),
                    if (user != null && user.isAdmin) ...[
                      _buildAdminMenuCard(context, 'Members', 'Check members', Icons.people_rounded, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MembersScreen()));
                      }),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      spacing: 20,
                      children: [
                        Expanded(
                          child: _buildMenuCard(context, 'Registration', 'Register daily reading', Icons.calendar_today_rounded, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyRegistrationScreen()));
                          }),
                        ),
                        Expanded(
                          child: _buildMenuCard(context, 'History', 'Check your previous  reading results', Icons.bar_chart_rounded, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CustomColor.subTextColor, width: 0.2),
          color: CustomColor.secondaryColor,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: CustomColor.textColor, shape: BoxShape.circle),
              child: Icon(icon, color: CustomColor.primaryColor, size: 35),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.afacad(fontSize: 23, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: CustomColor.textColor),
                  ),
                  Text(subtitle, style: GoogleFonts.afacad(fontSize: 17, color: Colors.grey[600], height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CustomColor.subTextColor, width: 0.2),
          color: CustomColor.secondaryColor,
        ),
        child: Column(
          spacing: 10,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: CustomColor.textColor, shape: BoxShape.circle),
              child: Icon(icon, color: CustomColor.primaryColor, size: 35),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.afacad(fontSize: 23, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: CustomColor.textColor),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.afacad(fontSize: 17, color: Colors.grey[600], height: 1.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    return Drawer(
      backgroundColor: CustomColor.primaryColor,
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: CustomColor.secondaryColor),
              accountName: Text(
                user?.name ?? 'User',
                style: GoogleFonts.afacad(fontWeight: FontWeight.bold, fontSize: 20, color: CustomColor.textColor),
              ),
              accountEmail: Text(user?.area ?? '', style: GoogleFonts.afacad(color: CustomColor.subTextColor, fontSize: 16)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: CustomColor.textColor,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: GoogleFonts.afacad(fontWeight: FontWeight.bold, fontSize: 24, color: CustomColor.primaryColor),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                'Logout',
                style: GoogleFonts.afacad(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                // Close drawer first
                Navigator.pop(context);

                // Show confirmation dialog or just logout
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const SignInScreen()), (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
