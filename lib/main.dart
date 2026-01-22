import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'provider/auth_provider.dart';
import 'provider/daily_provider.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_services.dart';
import 'services/notification_service.dart';
import 'services/app_pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // status bar background
      statusBarIconBrightness: Brightness.light, // Android icons → white
      statusBarBrightness: Brightness.dark, // iOS icons → white
    ),
  );

  await NotificationService().init();
  NotificationService().notificationHandler();

  await AppPref.appPref.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => DailyProvider()),
      ],
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
