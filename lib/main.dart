import 'package:flutter/material.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/screens/EditExerciseScreen.dart';
import 'package:gymf/ui/screens/ExerciseListScreen.dart';
import 'package:gymf/ui/screens/WorkoutPlanScreen.dart';
import 'package:gymf/ui/screens/auth/login_screen.dart';
import 'package:gymf/ui/screens/auth/signup_screen.dart';
import 'package:gymf/ui/screens/auth/complete_profile_screen.dart';
import 'package:gymf/ui/screens/dashboard_screen.dart';
import 'package:gymf/ui/screens/exercise_submission_screen.dart';
import 'package:gymf/ui/screens/home_screen.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoadingApp());
}

class LoadingApp extends StatefulWidget {
  const LoadingApp({super.key});

  @override
  State<LoadingApp> createState() => _LoadingAppState();
}

class _LoadingAppState extends State<LoadingApp> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🔄 شروع مقداردهی اولیه Supabase...');
      await Supabase.initialize(
        url: 'https://fxikasjkeaymhlfqsxgc.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4aWthc2prZWF5bWhsZnFzeGdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyOTA5NzAsImV4cCI6MjA1NTg2Njk3MH0.jhMtEI-aV3EkzTePTcsTSOaW6C6KlAt8kIxNBCpLY4o',
      );
      print('✅ Supabase با موفقیت مقداردهی شد.');
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ خطا در مقداردهی اولیه Supabase: $e');
      setState(() {
        _errorMessage = 'خطا در اتصال به سرور: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isInitialized = false;
                    });
                    _initializeApp();
                  },
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    print(
      '🔄 بررسی سشن Supabase: ${Supabase.instance.client.auth.currentSession}',
    );
    return const MyApp();
  }
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
        ChangeNotifierProvider(
          create: (context) => ExerciseProvider(context), // اصلاح با context
        ),
        ChangeNotifierProxyProvider<AuthProvider, WorkoutPlanProvider>(
          create: (context) => WorkoutPlanProvider(context),
          update: (context, auth, previous) {
            if (previous != null) {
              previous.updateAuth(auth);
            }
            return WorkoutPlanProvider(context)..updateAuth(auth);
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          // دسترسی به context بعد از مقداردهی Providerها
          final exerciseProvider = Provider.of<ExerciseProvider>(
            context,
            listen: false,
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gym App',
            theme: ThemeData.dark().copyWith(
              primaryColor: Colors.yellow,
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: Colors.yellow,
                secondary: Colors.amber,
              ),
            ),
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/complete-profile': (context) => const CompleteProfileScreen(),
              '/dashboard': (context) => DashboardScreen(),
              '/home': (context) => HomeScreen(),
              '/workout-plan': (context) => const WorkoutPlanScreen(),
              '/exercise-list':
                  (context) => const ExerciseListScreen(), // مسیر جدید
              '/submit-exercise':
                  (context) => const ExerciseSubmissionScreen(), // مسیر جدید
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/edit-exercise') {
                final exercise = settings.arguments as ExerciseModel;
                return MaterialPageRoute(
                  builder: (context) => EditExerciseScreen(exercise: exercise),
                );
              }
              return null;
            },
          );
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
          print('🔄 در حال بررسی وضعیت احراز هویت...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          print('❌ خطا در بررسی وضعیت احراز هویت: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'خطا در بررسی وضعیت: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('رفتن به صفحه ورود'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.data == true) {
          print('✅ کاربر وارد شده است، انتقال به داشبورد...');
          return const DashboardScreen();
        } else {
          print('🔑 کاربر وارد نشده است، انتقال به صفحه ورود...');
          return const LoginScreen();
        }
      },
    );
  }
}
