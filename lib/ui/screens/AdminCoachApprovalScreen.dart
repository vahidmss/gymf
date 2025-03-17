import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/core/services/CoachRegistrationService.dart';
import 'package:gymf/data/models/PendingCoachModel.dart';

class AdminCoachApprovalScreen extends StatefulWidget {
  const AdminCoachApprovalScreen({super.key});

  @override
  _AdminCoachApprovalScreenState createState() =>
      _AdminCoachApprovalScreenState();
}

class _AdminCoachApprovalScreenState extends State<AdminCoachApprovalScreen> {
  late Future<List<PendingCoachModel>> _pendingRequests;

  @override
  void initState() {
    super.initState();
    _pendingRequests = CoachRegistrationService().getPendingCoachRequests();
  }

  Future<void> _approveCoach(String userId) async {
    try {
      await CoachRegistrationService().approveCoach(userId);
      setState(() {
        _pendingRequests = CoachRegistrationService().getPendingCoachRequests();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('مربی با موفقیت تأیید شد!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
    }
  }

  Future<void> _rejectCoach(String userId) async {
    try {
      await CoachRegistrationService().rejectCoach(userId);
      setState(() {
        _pendingRequests = CoachRegistrationService().getPendingCoachRequests();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('درخواست رد شد!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $e')));
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
            'تأیید مربی‌ها',
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
        body: FutureBuilder<List<PendingCoachModel>>(
          future: _pendingRequests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'خطا: ${snapshot.error}',
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'درخواستی وجود ندارد',
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                ),
              );
            }

            final requests = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
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
                          'نام: ${request.name ?? 'نامشخص'}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'بیوگرافی: ${request.bio ?? 'نامشخص'}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'گواهینامه‌ها: ${request.certifications.isNotEmpty ? request.certifications.join(', ') : 'ندارد'}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'دستاوردها: ${request.achievements.isNotEmpty ? request.achievements.join(', ') : 'ندارد'}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سال‌های تجربه: ${request.experienceYears ?? 'نامشخص'}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تعداد شاگردها: ${request.studentCount}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'امتیاز: ${request.rating}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تاریخ درخواست: ${request.createdAt.toString().substring(0, 10)}',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _approveCoach(request.id),
                              child: Text(
                                'تأیید',
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _rejectCoach(request.id),
                              child: Text(
                                'رد',
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
