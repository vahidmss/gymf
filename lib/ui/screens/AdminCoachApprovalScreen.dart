import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymf/core/services/AdminService.dart';
import 'package:gymf/data/models/PendingCoachModel.dart';

class AdminCoachApprovalScreen extends StatefulWidget {
  const AdminCoachApprovalScreen({super.key});

  @override
  State<AdminCoachApprovalScreen> createState() =>
      _AdminCoachApprovalScreenState();
}

class _AdminCoachApprovalScreenState extends State<AdminCoachApprovalScreen> {
  List<PendingCoachModel> _pendingCoaches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingCoaches();
  }

  Future<void> _loadPendingCoaches() async {
    try {
      final service = AdminService();
      final pendingCoaches = await service.fetchPendingCoaches();
      setState(() {
        _pendingCoaches = pendingCoaches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در بارگذاری درخواست‌ها: $e')));
    }
  }

  Future<void> _approveCoach(String pendingId, String userId) async {
    try {
      final service = AdminService();
      await service.approveCoach(pendingId, userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('مربی با موفقیت تأیید شد!')));
      _loadPendingCoaches();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در تأیید مربی: $e')));
    }
  }

  Future<void> _rejectCoach(String pendingId) async {
    try {
      final service = AdminService();
      await service.rejectCoach(pendingId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('درخواست مربی رد شد!')));
      _loadPendingCoaches();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در رد مربی: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تأیید مربی‌ها',
          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pendingCoaches.isEmpty
              ? Center(
                child: Text(
                  'هیچ درخواست در انتظاری وجود ندارد!',
                  style: GoogleFonts.vazirmatn(fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingCoaches.length,
                itemBuilder: (context, index) {
                  final coach = _pendingCoaches[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coach.username,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'مدارک: ${coach.certifications.join(', ')}',
                            style: GoogleFonts.vazirmatn(fontSize: 16),
                          ),
                          Text(
                            'افتخارات: ${coach.achievements.join(', ')}',
                            style: GoogleFonts.vazirmatn(fontSize: 16),
                          ),
                          Text(
                            'سال تجربه: ${coach.experienceYears}',
                            style: GoogleFonts.vazirmatn(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: نمایش مدارک هویتی
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(coach.identityDocumentUrl),
                                    ),
                                  );
                                },
                                child: Text(
                                  'مشاهده مدارک هویتی',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: نمایش مدارک مربی‌گری
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(coach.certificatesUrl),
                                    ),
                                  );
                                },
                                child: Text(
                                  'مشاهده مدارک مربی‌گری',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed:
                                    () => _approveCoach(coach.id, coach.userId),
                                child: Text(
                                  'تأیید',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _rejectCoach(coach.id),
                                child: Text(
                                  'رد',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
