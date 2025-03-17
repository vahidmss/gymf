import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gymf/core/services/CoachRegistrationService.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';

class RegisterAsCoachScreen extends StatefulWidget {
  const RegisterAsCoachScreen({super.key});

  @override
  State<RegisterAsCoachScreen> createState() => _RegisterAsCoachScreenState();
}

class _RegisterAsCoachScreenState extends State<RegisterAsCoachScreen> {
  final _certificationsController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  String? _identityDocumentPath;
  String? _certificatesPath;
  bool _isLoading = false;

  Future<void> _pickFile(bool isIdentity) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isIdentity) {
          _identityDocumentPath = result.files.single.path;
        } else {
          _certificatesPath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _submitApplication() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لطفاً وارد شوید!')));
      return;
    }

    if (_identityDocumentPath == null || _certificatesPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً تمام مدارک را آپلود کنید!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = CoachRegistrationService();
      await service.submitCoachApplication(
        userId: userId,
        certifications:
            _certificationsController.text
                .split(',')
                .map((e) => e.trim())
                .toList(),
        achievements:
            _achievementsController.text
                .split(',')
                .map((e) => e.trim())
                .toList(),
        experienceYears: int.parse(_experienceYearsController.text),
        identityDocumentPath: _identityDocumentPath!,
        certificatesPath: _certificatesPath!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('درخواست شما با موفقیت ارسال شد!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ارسال درخواست: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ثبت‌نام به‌عنوان مربی',
          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _certificationsController,
              decoration: const InputDecoration(
                labelText: 'مدارک (با کاما جدا کنید)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _achievementsController,
              decoration: const InputDecoration(
                labelText: 'افتخارات (با کاما جدا کنید)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _experienceYearsController,
              decoration: const InputDecoration(labelText: 'سال تجربه'),
              keyboardType: TextInputType.number, // جابه‌جایی به اینجا
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickFile(true),
              child: Text(
                _identityDocumentPath == null
                    ? 'آپلود مدارک هویتی'
                    : 'مدارک هویتی انتخاب شد',
                style: GoogleFonts.vazirmatn(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickFile(false),
              child: Text(
                _certificatesPath == null
                    ? 'آپلود مدارک مربی‌گری'
                    : 'مدارک مربی‌گری انتخاب شد',
                style: GoogleFonts.vazirmatn(),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: _submitApplication,
                  child: Text('ارسال درخواست', style: GoogleFonts.vazirmatn()),
                ),
          ],
        ),
      ),
    );
  }
}
