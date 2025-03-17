import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gymf/core/utils/app_routes.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.blueGrey.shade900,
            Colors.yellow.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/logo.png', height: 100),
                const SizedBox(height: 40),
                Text(
                  'ورود',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                ),
                const SizedBox(height: 40),
                const _LoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(BuildContext context) async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً ایمیل/یوزرنیم و رمز عبور را وارد کنید'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      print('🔄 تلاش برای ورود با ورودی: ${_usernameController.text}');
      await authProvider.signInWithUsername(
        _usernameController.text,
        _passwordController.text,
      );
      print('✅ ورود موفق، کاربر: ${authProvider.currentUser?.username}');
      if (authProvider.currentUser != null) {
        if (authProvider.isAdmin) {
          Navigator.pushReplacementNamed(context, AppRoutes.adminCoachApproval);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      } else {
        throw Exception('کاربر بارگذاری نشد.');
      }
    } catch (e) {
      print('❌ خطا در ورود: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ورود: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          controller: _usernameController,
          label: 'ایمیل یا یوزرنیم',
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passwordController,
          label: 'رمز عبور',
          obscureText: true,
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator()
            : CustomButton(
              text: 'ورود',
              onPressed: () => _handleSignIn(context),
            ),
        const SizedBox(height: 15),
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => const SignUpSheet(),
                    );
                  },
          child: Text(
            'ثبت‌نام',
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              color: Colors.yellowAccent,
            ),
          ),
        ),
      ],
    );
  }
}

class SignUpSheet extends StatelessWidget {
  const SignUpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: const _SignUpForm(),
          ),
        );
      },
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(BuildContext context) async {
    if (_phoneController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً همه فیلدها را پر کنید')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      print('🔄 ثبت‌نام با شماره موبایل: ${_phoneController.text}');
      await authProvider.signUpWithPhone(
        _phoneController.text,
        _usernameController.text,
        _passwordController.text,
        'athlete', // نقش پیش‌فرض ورزشکار
      );
      if (mounted) {
        Navigator.pop(context); // بستن BottomSheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کد OTP برای شما ارسال شد، لطفاً آن را تأیید کنید.'),
          ),
        );
      }
    } catch (e) {
      print('❌ خطا در ثبت‌نام: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ثبت‌نام: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ثبت‌نام',
          style: GoogleFonts.vazirmatn(
            fontSize: 24,
            color: Colors.yellowAccent,
          ),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _phoneController,
          label: 'شماره موبایل',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        CustomTextField(controller: _usernameController, label: 'یوزرنیم'),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passwordController,
          label: 'رمز عبور',
          obscureText: true,
        ),
        const SizedBox(height: 20),
        _isLoading
            ? const CircularProgressIndicator()
            : CustomButton(
              text: 'ارسال OTP',
              onPressed: () => _handleSignUp(context),
            ),
      ],
    );
  }
}
