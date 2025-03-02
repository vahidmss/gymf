import 'package:flutter/material.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/ui/screens/WorkoutPlanScreen.dart';
import 'package:gymf/ui/screens/auth/login_screen.dart';
import 'package:gymf/ui/screens/auth/signup_screen.dart';
import 'package:gymf/ui/screens/auth/complete_profile_screen.dart';
import 'package:gymf/ui/screens/dashboard_screen.dart';
import 'package:gymf/ui/screens/home_screen.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fxikasjkeaymhlfqsxgc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4aWthc2prZWF5bWhsZnFzeGdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyOTA5NzAsImV4cCI6MjA1NTg2Njk3MH0.jhMtEI-aV3EkzTePTcsTSOaW6C6KlAt8kIxNBCpLY4o',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider();
            authProvider.initialize();
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (context) => ExerciseProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WorkoutPlanProvider>(
          create: (context) => WorkoutPlanProvider(context),
          update:
              (context, auth, previous) =>
                  WorkoutPlanProvider(context)
                    ..updateAuth(auth), // یه متد جدید برای آپدیت
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gym App',
        theme: ThemeData.dark(),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/complete-profile': (context) => const CompleteProfileScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/home': (context) => HomeScreen(),
          '/workout-plan': (context) => WorkoutApp(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return FutureBuilder<bool>(
      future: authProvider.checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.data == true) {
          return DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
