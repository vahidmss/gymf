import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/logo.png', height: 100),
              const SizedBox(height: 40),
              const Text(
                'ورود',
                style: TextStyle(
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
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).signInWithUsername(_usernameController.text, _passwordController.text);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
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

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).signInWithGoogle(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ورود با گوگل: $e')));
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
        CustomTextField(controller: _usernameController, label: 'یوزرنیم'),
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
        CustomButton(
          text: 'ورود با جیمیل',
          onPressed: _isLoading ? null : () => _handleGoogleSignIn(context),
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
          child: const Text(
            'ثبت‌نام',
            style: TextStyle(fontSize: 16, color: Colors.yellowAccent),
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
  final TextEditingController _coachCodeController = TextEditingController();
  String _selectedRole = 'athlete';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _coachCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AuthProvider>(context, listen: false).signUpWithPhone(
        _phoneController.text,
        _usernameController.text,
        _passwordController.text,
        _selectedRole,
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
        const Text(
          'ثبت‌نام',
          style: TextStyle(fontSize: 24, color: Colors.yellowAccent),
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
        DropdownButton<String>(
          value: _selectedRole,
          items: const [
            DropdownMenuItem(
              value: 'athlete',
              child: Text('ورزشکار', style: TextStyle(color: Colors.white)),
            ),
            DropdownMenuItem(
              value: 'coach',
              child: Text('مربی', style: TextStyle(color: Colors.white)),
            ),
          ],
          onChanged: (value) => setState(() => _selectedRole = value!),
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.yellowAccent,
        ),
        if (_selectedRole == 'coach')
          CustomTextField(
            controller: _coachCodeController,
            label: 'کد تأیید مربی',
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
