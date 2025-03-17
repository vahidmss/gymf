import 'package:flutter/material.dart';
import 'package:gymf/core/utils/auth_wrapper.dart';
import 'package:gymf/core/utils/app_routes.dart';
import 'package:gymf/providers/CoachProvider.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/screens/AdminCoachApprovalScreen.dart';
import 'package:gymf/ui/screens/EditExerciseScreen.dart';
import 'package:gymf/ui/screens/ExerciseListScreen.dart';
import 'package:gymf/ui/screens/ProfileScreen.dart';
import 'package:gymf/ui/screens/RegisterAsCoachScreen.dart';
import 'package:gymf/ui/screens/WorkoutLogScreen.dart';
import 'package:gymf/ui/screens/WorkoutPlanScreen.dart';
import 'package:gymf/ui/screens/auth/login_screen.dart';
import 'package:gymf/ui/screens/auth/signup_screen.dart';
import 'package:gymf/ui/screens/auth/complete_profile_screen.dart';
import 'package:gymf/ui/screens/dashboard_screen.dart';
import 'package:gymf/ui/screens/exercise_submission_screen.dart';
import 'package:gymf/ui/screens/home_screen.dart';
import 'package:gymf/ui/screens/coaches_screen.dart';
import 'package:gymf/data/models/exercise_model.dart';
import 'package:gymf/ui/screens/edit_profile_screen.dart'; // اضافه کردن این import
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
        ChangeNotifierProvider(create: (context) => ExerciseProvider(context)),
        ChangeNotifierProxyProvider<AuthProvider, WorkoutPlanProvider>(
          create: (context) => WorkoutPlanProvider(context),
          update: (context, auth, previous) {
            if (previous != null) {
              previous.updateAuth(auth);
            }
            return previous ?? WorkoutPlanProvider(context)
              ..updateAuth(auth);
          },
        ),
        ChangeNotifierProvider(create: (context) => CoachProvider(context)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gym App',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.yellow,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Colors.yellow,
            secondary: Colors.amber,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.signup: (context) => const SignupScreen(),
          AppRoutes.completeProfile: (context) => const CompleteProfileScreen(),
          AppRoutes.dashboard: (context) => DashboardScreen(),
          AppRoutes.home: (context) => HomeScreen(),
          AppRoutes.workoutPlan: (context) => const WorkoutPlanScreen(),
          AppRoutes.exerciseList: (context) => const ExerciseListScreen(),
          AppRoutes.submitExercise:
              (context) => const ExerciseSubmissionScreen(),
          AppRoutes.coaches: (context) => const CoachesScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.registerAsCoach: (context) => const RegisterAsCoachScreen(),
          AppRoutes.adminCoachApproval:
              (context) => const AdminCoachApprovalScreen(),
          AppRoutes.workoutLog: (context) => const WorkoutLogScreen(),
          AppRoutes.editProfile: (context) => const EditProfileScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.editExercise) {
            final exercise = settings.arguments as ExerciseModel;
            return MaterialPageRoute(
              builder: (context) => EditExerciseScreen(exercise: exercise),
            );
          }
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  body: Center(child: Text('صفحه ${settings.name} پیدا نشد!')),
                ),
          );
        },
      ),
    );
  }
}
