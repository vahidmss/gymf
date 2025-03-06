import 'package:flutter/material.dart';
import 'package:gymf/ui/screens/WorkoutLogScreen.dart';
import 'package:gymf/ui/screens/coaches_screen.dart';
import 'package:gymf/ui/screens/exercise_submission_screen.dart';
import 'package:gymf/ui/screens/home_screen.dart';
import 'package:gymf/ui/screens/profile_screen.dart';
import 'package:gymf/ui/screens/WorkoutPlanScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    CoachesScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("داشبورد")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'منوی کاربری',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("پروفایل"),
              onTap: () {
                Navigator.pop(context);
                _onTabTapped(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text("ثبت تمرین"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ExerciseSubmissionScreen(), // صفحه ثبت تمرین
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text("ثبت برنامه تمرین"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutPlanScreen(), // صفحه ثبت تمرین
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text("ثبت تمرین روز"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutLogScreen(), // ص
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("خروج از حساب"),
              onTap: () {
                print("خروج از حساب");
              },
            ),
          ],
        ),
      ),

      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "خانه"),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "مربیان",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "پروفایل"),
        ],
      ),
    );
  }
}
