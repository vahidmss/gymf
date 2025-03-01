import 'package:flutter/material.dart';
import 'package:gymf/core/services/otp_service.dart';
import 'package:gymf/ui/screens/auth/verify_otp_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _coachCodeController = TextEditingController();
  String _selectedRole = 'athlete';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _coachCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                _buildTitle(),
                const SizedBox(height: 60),
                CustomTextField(
                  controller: _phoneController,
                  label: 'شماره موبایل',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _usernameController,
                  label: 'یوزرنیم',
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _passwordController,
                  label: 'رمز عبور',
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                _buildRoleDropdown(),
                if (_selectedRole == 'coach') _buildCoachCodeField(),
                const SizedBox(height: 40),
                _buildOtpButton(authProvider),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/logo.png',
      height: 120,
      width: 120,
      color: Colors.yellowAccent,
    );
  }

  Widget _buildTitle() {
    return const Text(
      'ثبت‌نام',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.yellowAccent,
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButton<String>(
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
    );
  }

  Widget _buildCoachCodeField() {
    return Column(
      children: [
        const SizedBox(height: 30),
        CustomTextField(
          controller: _coachCodeController,
          label: 'کد تأیید مربی',
        ),
      ],
    );
  }

  Widget _buildOtpButton(AuthProvider authProvider) {
    return CustomButton(
      text: 'ارسال OTP',
      onPressed: () async {
        if (!OtpService().isValidIranianPhoneNumber(_phoneController.text)) {
          _showSnackbar(
            'شماره موبایل نامعتبر است. لطفاً شماره‌ای با فرمت 09XXXXXXXXX وارد کنید.',
          );
          return;
        }
        if (_selectedRole == 'coach' && _coachCodeController.text.isEmpty) {
          _showSnackbar('کد تأیید مربی الزامی است.');
          return;
        }
        try {
          await authProvider.signUpWithPhone(
            _phoneController.text,
            _usernameController.text,
            _passwordController.text,
            _selectedRole,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(phone: _phoneController.text),
            ),
          );
        } catch (e) {
          _showSnackbar('خطا: ${e.toString()}');
        }
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        content: Text(
          message,
          style: const TextStyle(color: Colors.yellowAccent),
        ),
      ),
    );
  }
}
