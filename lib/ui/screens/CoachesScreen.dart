import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/data/models/CoachModel.dart';
import 'package:gymf/providers/CoachProvider.dart';
import 'package:provider/provider.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    coachProvider.fetchCoaches();
  }

  Widget _buildCoachCard(CoachModel coach) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            _isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isDarkTheme ? Colors.yellow.withOpacity(0.2) : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
              coach.profileImageUrl ?? 'https://via.placeholder.com/150',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  style: GoogleFonts.vazirmatn(
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < coach.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.yellow,
                      size: 16,
                    );
                  }),
                ),
                Text(
                  coach.studentCount > 0
                      ? '${coach.studentCount} شاگرد'
                      : 'هنوز شاگردی ندارد',
                  style: GoogleFonts.vazirmatn(
                    color: _isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  coach.likeCount > 0 ? '${coach.likeCount} لایک' : 'بدون نظر',
                  style: GoogleFonts.vazirmatn(
                    color: _isDarkTheme ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final coachProvider = Provider.of<CoachProvider>(
                    context,
                    listen: false,
                  );
                  coachProvider.sendConsultationRequest(
                    coach.id,
                    'consultation',
                    'لطفاً راهنمایی کنید',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('درخواست مشاوره ارسال شد!')),
                  );
                },
                child: Text('مشاوره'),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                onPressed: () {
                  final coachProvider = Provider.of<CoachProvider>(
                    context,
                    listen: false,
                  );
                  coachProvider.sendConsultationRequest(
                    coach.id,
                    'workout_plan',
                    'برنامه تمرینی می‌خوام',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('درخواست برنامه تمرینی ارسال شد!'),
                    ),
                  );
                },
                child: Text('برنامه'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX();
  }

  @override
  Widget build(BuildContext context) {
    final coachProvider = Provider.of<CoachProvider>(context);
    final coaches = coachProvider.coaches;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkTheme ? Colors.blueGrey.shade900 : Colors.white,
        elevation: 0,
        title: Text(
          'لیست مربی‌ها',
          style: GoogleFonts.vazirmatn(
            color: _isDarkTheme ? Colors.yellow : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isDarkTheme ? Icons.brightness_7 : Icons.brightness_4),
            onPressed: () {
              setState(() {
                _isDarkTheme = !_isDarkTheme;
              });
            },
          ),
        ],
      ),
      body:
          coachProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : coaches.isEmpty
              ? Center(
                child: Text(
                  'هیچ مربی‌ای یافت نشد!',
                  style: GoogleFonts.vazirmatn(
                    color: _isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: coaches.length,
                itemBuilder: (context, index) {
                  return _buildCoachCard(coaches[index]);
                },
              ),
    );
  }
}
