import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/core/utils/app_routes.dart';
import 'package:gymf/main.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'خوش اومدی، ${authProvider.currentUser?.username ?? 'کاربر'}!',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'امروز چه تمرینی داری؟',
                style: GoogleFonts.vazirmatn(
                  color: Colors.yellow,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 24),
              // کارت برای نمایش تمرینات پیشنهادی
              Card(
                color: Colors.blueGrey.shade800.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: Colors.yellow,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تمرین پیشنهادی امروز',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تمرینات پا و شکم - 45 دقیقه',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.workoutPlan);
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // کارت برای نمایش مربیان
              Card(
                color: Colors.blueGrey.shade800.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: Colors.yellow, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مربیان ما',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'با مربیان حرفه‌ای آشنا شو',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.coaches);
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
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
