import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/core/services/CoachRegistrationService.dart';
import 'package:gymf/data/models/PendingCoachModel.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';

class RegisterAsCoachScreen extends StatefulWidget {
  const RegisterAsCoachScreen({super.key});

  @override
  _RegisterAsCoachScreenState createState() => _RegisterAsCoachScreenState();
}

class _RegisterAsCoachScreenState extends State<RegisterAsCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _certificationsController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser!.id;

    final request = PendingCoachModel(
      id: userId,
      name: _nameController.text,
      bio: _bioController.text,
      certifications:
          _certificationsController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
      achievements: [], // چون توی فرم نیست، خالی می‌ذاریم
      experienceYears: int.tryParse(_experienceYearsController.text),
      studentCount: 0, // چون توی فرم نیست، پیش‌فرض 0
      rating: 0.0, // چون توی فرم نیست، پیش‌فرض 0.0
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await CoachRegistrationService().submitCoachRequest(request);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('درخواست شما با موفقیت ثبت شد!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        appBar: AppBar(
          title: Text(
            'درخواست مربی شدن',
            style: GoogleFonts.vazirmatn(
              textStyle: const TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'نام کامل',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً نام کامل خود را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'بیوگرافی',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً بیوگرافی خود را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _certificationsController,
                  decoration: InputDecoration(
                    labelText: 'گواهینامه‌ها (با کاما جدا کنید)',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً گواهینامه‌ها را وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _experienceYearsController,
                  decoration: InputDecoration(
                    labelText: 'سال‌های تجربه',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً سال‌های تجربه را وارد کنید';
                    }
                    if (int.tryParse(value) == null) {
                      return 'لطفاً یک عدد معتبر وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                            'ارسال درخواست',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
