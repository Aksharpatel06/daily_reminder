import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/services/auth_services.dart';
import 'package:provider/provider.dart';
import 'provider/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService().init();
  await NotificationService().scheduleDailyNotification();

  // await AppPref.appPref.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => AuthProvider())],
      child: MaterialApp(
        title: 'Daily Reading Register',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1), brightness: Brightness.light),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
              TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
            },
          ),
        ),
        home: AuthService.authServices.currentUser != null ? const HomeScreen() : const SignInScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
