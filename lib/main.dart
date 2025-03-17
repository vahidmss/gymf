import 'package:flutter/material.dart';
import 'package:gymf/providers/CoachProvider.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/screens/AdminCoachApprovalScreen.dart';
import 'package:gymf/ui/screens/EditExerciseScreen.dart';
import 'package:gymf/ui/screens/ExerciseListScreen.dart';
import 'package:gymf/ui/screens/ProfileScreen.dart';
import 'package:gymf/ui/screens/RegisterAsCoachScreen.dart';
import 'package:gymf/ui/screens/WorkoutPlanScreen.dart';
import 'package:gymf/ui/screens/auth/login_screen.dart';
import 'package:gymf/ui/screens/auth/signup_screen.dart';
import 'package:gymf/ui/screens/auth/complete_profile_screen.dart';
import 'package:gymf/ui/screens/dashboard_screen.dart';
import 'package:gymf/ui/screens/exercise_submission_screen.dart';
import 'package:gymf/ui/screens/home_screen.dart';
import 'package:gymf/ui/screens/coaches_screen.dart'; // اضافه کردن CoachesScreen
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

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String completeProfile = '/complete-profile';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String workoutPlan = '/workout-plan';
  static const String exerciseList = '/exercise-list';
  static const String submitExercise = '/submit-exercise';
  static const String editExercise = '/edit-exercise';
  static const String coaches = '/coaches';
  static const String profile = '/profile'; // مسیر جدید
  static const String registerAsCoach = '/register-as-coach'; // مسیر جدید
  static const String adminCoachApproval = '/admin-coach-approval'; // مسیر جدید
  static const String workoutLog = '/workout-log';
  static const String editProfile = '/edit-profile'; // اضافه کردن مسیر جدید
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
          AppRoutes.profile: (context) => const ProfileScreen(), // مسیر جدید
          AppRoutes.registerAsCoach:
              (context) => const RegisterAsCoachScreen(), // مسیر جدید
          AppRoutes.adminCoachApproval:
              (context) => const AdminCoachApprovalScreen(), // مسیر جدید
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
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isAuthenticated;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final isAuthenticated = await authProvider.checkAuthStatus();
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
      if (isAuthenticated) {
        final exerciseProvider = Provider.of<ExerciseProvider>(
          context,
          listen: false,
        );
        final workoutPlanProvider = Provider.of<WorkoutPlanProvider>(
          context,
          listen: false,
        );
        final coachProvider = Provider.of<CoachProvider>(
          context,
          listen: false,
        );

        await authProvider.loadInitialData(
          exerciseProvider: exerciseProvider,
          workoutPlanProvider: workoutPlanProvider,
          coachProvider: coachProvider,
        );
        // بعد از اتمام لود، تغییر حالت رو اعمال می‌کنیم
        authProvider.notifyListeners();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isAuthenticated == null) {
      print('🔄 در حال بررسی وضعیت احراز هویت...');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      print('❌ خطا در بررسی وضعیت احراز هویت: $_errorMessage');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'خطا در بررسی وضعیت: $_errorMessage',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text('رفتن به صفحه ورود'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated == true) {
      print('✅ کاربر وارد شده است، انتقال به داشبورد...');
      if (authProvider.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const DashboardScreen();
    } else {
      print('🔑 کاربر وارد نشده است، انتقال به صفحه ورود...');
      return const LoginScreen();
    }
  }
}
