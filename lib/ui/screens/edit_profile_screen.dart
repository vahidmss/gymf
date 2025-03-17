import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController.text = authProvider.currentUser?.username ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
            'ویرایش پروفایل',
            style: GoogleFonts.vazirmatn(
              textStyle: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'نام کاربری',
                  labelStyle: GoogleFonts.vazirmatn(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.vazirmatn(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final newUsername = _usernameController.text;
                  try {
                    await authProvider.completeProfile(
                      newUsername,
                      'user',
                    ); // فرض می‌کنیم نقش تغییر نمی‌کنه
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('پروفایل با موفقیت به‌روزرسانی شد!'),
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('خطا: $e')));
                  }
                },
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
                child: Text(
                  'ذخیره تغییرات',
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
