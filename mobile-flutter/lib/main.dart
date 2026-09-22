import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/api/auth_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'features/reservations/screens/staff_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar icons to match the dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Bootstrap auth — restores session from secure storage if available
  await AuthService.instance.initialize();

  runApp(const ChargeSyncApp());
}

class ChargeSyncApp extends StatelessWidget {
  const ChargeSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;

    // Determine the initial screen based on role
    Widget home;
    if (!auth.isAuthenticated) {
      home = const SignInScreen();
    } else if (auth.isStaff) {
      home = const StaffDashboardScreen();
    } else {
      home = const HomeScreen(); // Driver dashboard
    }

    return MaterialApp(
      title: 'ChargeSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: home,
    );
  }
}
