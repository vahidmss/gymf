import 'package:flutter/material.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/ui/widgets/custom_button.dart';
import 'package:gymf/ui/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _coachCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _selectedRole = 'athlete';
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _coachCodeController.dispose();
    super.dispose();
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // بستن کیبورد

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).completeProfile(_usernameController.text.trim(), _selectedRole);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('خطا در ثبت اطلاعات: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تکمیل پروفایل')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _usernameController,
                label: 'یوزرنیم',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'یوزرنیم نمی‌تواند خالی باشد!'
                            : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'athlete', child: Text('ورزشکار')),
                  DropdownMenuItem(value: 'coach', child: Text('مربی')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedRole = value;
                    _coachCodeController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_selectedRole == 'coach')
                CustomTextField(
                  controller: _coachCodeController,
                  label: 'کد تأیید مربی',
                  validator:
                      (value) =>
                          value == '18946704' ? null : 'کد تأیید نادرست است!',
                ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(
                    text: 'ثبت اطلاعات',
                    onPressed: _submitProfile,
                    backgroundColor: Colors.blueAccent,
                    textColor: Colors.white,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
