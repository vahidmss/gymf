import 'package:flutter/material.dart';
import 'package:gymf/core/utils/app_routes.dart';
import 'package:gymf/providers/CoachProvider.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/providers/exercise_provider.dart';
import 'package:gymf/ui/screens/auth/login_screen.dart';
import 'package:gymf/ui/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';

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
