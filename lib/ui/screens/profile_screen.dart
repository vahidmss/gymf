import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/main.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            'پروفایل کاربری',
            style: GoogleFonts.vazirmatn(
              textStyle: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 5),
                  Shadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 10),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body:
            authProvider.currentUser == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // تصویر پروفایل
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.yellow.shade800,
                        child:
                            authProvider.currentUser?.profileImageUrl != null
                                ? ClipOval(
                                  child: Image.network(
                                    authProvider.currentUser!.profileImageUrl!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                  ),
                                )
                                : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(height: 16),
                      // نام کاربری
                      Text(
                        authProvider.currentUser?.username ?? 'کاربر ناشناس',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 5),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // نقش کاربر
                      Text(
                        authProvider.isCoach
                            ? 'مربی'
                            : authProvider.isAdmin
                            ? 'ادمین'
                            : 'کاربر عادی',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.yellow,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // اطلاعات کاربر
                      Card(
                        color: Colors.blueGrey.shade800.withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.email, color: Colors.yellow),
                                  const SizedBox(width: 8),
                                  Text(
                                    authProvider.currentUser?.email ??
                                        'ایمیل ثبت نشده',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.yellow),
                                  const SizedBox(width: 8),
                                  Text(
                                    authProvider.currentUser?.bio ??
                                        'بیوگرافی ثبت نشده',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.yellow,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تاریخ عضویت: ${authProvider.currentUser!.createdAt.toString().substring(0, 10)}',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // اطلاعات مربی (فقط برای مربی‌ها)
                      if (authProvider.isCoach) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Colors.blueGrey.shade800.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اطلاعات مربی',
                                  style: GoogleFonts.vazirmatn(
                                    color: Colors.yellow,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.yellow,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'امتیاز: ${authProvider.currentUser!.rating.toStringAsFixed(1)}',
                                      style: GoogleFonts.vazirmatn(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.group,
                                      color: Colors.yellow,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تعداد شاگردان: ${authProvider.currentUser!.studentCount}',
                                      style: GoogleFonts.vazirmatn(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.work,
                                      color: Colors.yellow,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'سال‌های تجربه: ${authProvider.currentUser!.experienceYears ?? 'نامشخص'}',
                                      style: GoogleFonts.vazirmatn(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (authProvider
                                    .currentUser!
                                    .certifications
                                    .isNotEmpty) ...[
                                  Text(
                                    'گواهینامه‌ها:',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.yellow,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...authProvider.currentUser!.certifications
                                      .map(
                                        (cert) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 16.0,
                                          ),
                                          child: Text(
                                            '- $cert',
                                            style: GoogleFonts.vazirmatn(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ],
                                const SizedBox(height: 8),
                                if (authProvider
                                    .currentUser!
                                    .achievements
                                    .isNotEmpty) ...[
                                  Text(
                                    'دستاوردها:',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.yellow,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...authProvider.currentUser!.achievements
                                      .map(
                                        (achieve) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 16.0,
                                          ),
                                          child: Text(
                                            '- $achieve',
                                            style: GoogleFonts.vazirmatn(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // دکمه ویرایش پروفایل
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.editProfile);
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: Text(
                          'ویرایش پروفایل',
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
                      const SizedBox(height: 16),
                      // دکمه خروج
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await authProvider.signOut();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('با موفقیت خارج شدید!'),
                              ),
                            );
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطا در خروج: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          'خروج از حساب',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
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
    );
  }
}
