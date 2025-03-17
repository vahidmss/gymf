import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/core/utils/app_routes.dart';
import 'package:gymf/main.dart';
import 'package:gymf/providers/auth_provider.dart';
import 'package:gymf/ui/screens/ExerciseListScreen.dart';
import 'package:gymf/ui/screens/coaches_screen.dart';
import 'package:gymf/ui/screens/home_screen.dart';
import 'package:gymf/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExerciseListScreen(),
    const CoachesScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: "خانه"),
    const BottomNavigationBarItem(
      icon: Icon(Icons.school, color: Colors.yellow),
      label: "مدرسه",
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center, color: Colors.greenAccent),
      label: "مربیان",
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person, color: Colors.blueAccent),
      label: "پروفایل",
    ),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('با موفقیت خارج شدید!')));
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در خروج: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
                'مدرسه بدنسازی',
                style: GoogleFonts.vazirmatn(
                  textStyle: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 5),
                      Shadow(
                        color: Colors.yellow.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.yellow),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      tooltip: 'منو',
                    ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.yellow),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اعلان‌ها به زودی!')),
                    );
                  },
                  tooltip: 'اعلان‌ها',
                ),
              ],
            ),
            drawer: Drawer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueGrey.shade900, Colors.yellow.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: AnimateList(
                    interval: 100.ms,
                    effects: [FadeEffect(duration: 600.ms), SlideEffect()],
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade900,
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'منوی کاربری',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 5),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              authProvider.currentUser?.username ?? 'کاربر',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          "پروفایل",
                          style: GoogleFonts.vazirmatn(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(3);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.add_circle,
                          color: Colors.greenAccent,
                        ),
                        title: Text(
                          "ثبت تمرین",
                          style: GoogleFonts.vazirmatn(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.submitExercise,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_today,
                          color: Colors.amber,
                        ),
                        title: Text(
                          "ثبت برنامه تمرین",
                          style: GoogleFonts.vazirmatn(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.workoutPlan);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.fitness_center,
                          color: Colors.greenAccent,
                        ),
                        title: Text(
                          "لیست مربیان",
                          style: GoogleFonts.vazirmatn(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(2);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.history,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          "ثبت تمرین روز",
                          style: GoogleFonts.vazirmatn(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.workoutLog);
                        },
                      ),
                      if (!authProvider.isCoach)
                        ListTile(
                          leading: const Icon(
                            Icons.add_moderator,
                            color: Colors.orangeAccent,
                          ),
                          title: Text(
                            "ثبت‌نام به‌عنوان مربی",
                            style: GoogleFonts.vazirmatn(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.registerAsCoach,
                            );
                          },
                        ),
                      if (authProvider.isAdmin)
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.purpleAccent,
                          ),
                          title: Text(
                            "تأیید مربی‌ها",
                            style: GoogleFonts.vazirmatn(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.adminCoachApproval,
                            );
                          },
                        ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: Text(
                          "خروج از حساب",
                          style: GoogleFonts.vazirmatn(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: _screens[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.blueGrey.shade900.withOpacity(0.8),
              selectedItemColor: Colors.yellow,
              unselectedItemColor: Colors.white54,
              selectedLabelStyle: GoogleFonts.vazirmatn(fontSize: 12),
              unselectedLabelStyle: GoogleFonts.vazirmatn(fontSize: 12),
              items: _navItems,
            ),
          )
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}
