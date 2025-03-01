import 'package:flutter/material.dart';
import 'package:gymf/core/services/otp_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../home_screen.dart';
import 'dart:async';

class VerifyOtpScreen extends StatefulWidget {
  final String phone;

  const VerifyOtpScreen({super.key, required this.phone});

  @override
  _VerifyOtpScreenState createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _otpController = TextEditingController();
  Timer? _resendTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;

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
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 30;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'تأیید OTP',
          style: TextStyle(color: Colors.yellowAccent),
        ),
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'کد تأیید را وارد کنید',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.yellowAccent,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 60),
                  CustomTextField(
                    controller: _otpController,
                    label: 'کد OTP',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: 'تأیید',
                    onPressed: () async {
                      try {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        await authProvider.verifyOtp(
                          widget.phone,
                          _otpController.text,
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.black,
                            content: Text(
                              _getErrorMessage(e.toString()),
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed:
                        _canResend
                            ? () async {
                              try {
                                final otpService = OtpService();
                                await otpService.sendOtp(widget.phone);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.black,
                                    content: Text(
                                      'OTP دوباره ارسال شد',
                                      style: TextStyle(
                                        color: Colors.yellowAccent,
                                      ),
                                    ),
                                  ),
                                );
                                _startResendTimer();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.black,
                                    content: Text(
                                      _getErrorMessage(e.toString()),
                                      style: const TextStyle(
                                        color: Colors.yellowAccent,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                            : null,
                    child: Text(
                      _canResend
                          ? 'ارسال مجدد OTP'
                          : 'ارسال مجدد در $_secondsRemaining ثانیه',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    switch (error) {
      case 'کد OTP نامعتبر است.':
        return 'کدی که وارد کردید اشتباه است. لطفاً دوباره امتحان کنید.';
      default:
        return 'خطای ناشناخته: $error';
    }
  }
}
