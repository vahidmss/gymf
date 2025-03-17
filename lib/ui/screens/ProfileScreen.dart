import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/core/services/ProfileService.dart';
import 'package:gymf/data/models/UserProfileModel.dart';
import 'package:provider/provider.dart';
import 'package:gymf/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لطفاً وارد شوید!')));
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final profileService = ProfileService();
      final profile = await profileService.fetchUserProfile(userId);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در بارگذاری پروفایل: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'پروفایل',
          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: صفحه ویرایش پروفایل
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ویژگی ویرایش به زودی اضافه می‌شود!'),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profile == null
              ? const Center(child: Text('پروفایلی یافت نشد!'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          _profile!.profileImageUrl ??
                              'https://via.placeholder.com/150',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _profile!.username,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _profile!.email ?? 'ایمیل ثبت نشده',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'درباره من',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profile!.bio ?? 'هنوز بیوگرافی ثبت نشده است.',
                      style: GoogleFonts.vazirmatn(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    if (_profile!.isCoach) ...[
                      Text(
                        'اطلاعات مربی‌گری',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مدارک: ${_profile!.certifications.isNotEmpty ? _profile!.certifications.join(', ') : 'ثبت نشده'}',
                        style: GoogleFonts.vazirmatn(fontSize: 16),
                      ),
                      Text(
                        'افتخارات: ${_profile!.achievements.isNotEmpty ? _profile!.achievements.join(', ') : 'ثبت نشده'}',
                        style: GoogleFonts.vazirmatn(fontSize: 16),
                      ),
                      Text(
                        'سال تجربه: ${_profile!.experienceYears?.toString() ?? 'ثبت نشده'}',
                        style: GoogleFonts.vazirmatn(fontSize: 16),
                      ),
                      Text(
                        'تعداد شاگردان: ${_profile!.studentCount}',
                        style: GoogleFonts.vazirmatn(fontSize: 16),
                      ),
                      Row(
                        children: [
                          Text(
                            'امتیاز: ${_profile!.rating.toStringAsFixed(1)}',
                            style: GoogleFonts.vazirmatn(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _profile!.rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.yellow,
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (!_profile!.isCoach)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register-as-coach');
                        },
                        child: Text(
                          'ثبت‌نام به‌عنوان مربی',
                          style: GoogleFonts.vazirmatn(),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
