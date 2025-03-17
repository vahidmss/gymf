import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCoachApprovalScreen extends StatefulWidget {
  const AdminCoachApprovalScreen({super.key});

  @override
  _AdminCoachApprovalScreenState createState() =>
      _AdminCoachApprovalScreenState();
}

class _AdminCoachApprovalScreenState extends State<AdminCoachApprovalScreen> {
  List<Map<String, dynamic>> _pendingCoaches = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingCoaches();
  }

  Future<void> _fetchPendingCoaches() async {
    try {
      final response = await _supabase
          .from('coaches')
          .select('*, profiles!coaches_user_id_fkey(username)')
          .eq('is_approved', false);
      setState(() {
        _pendingCoaches = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در بارگذاری درخواست‌ها: $e')));
    }
  }

  Future<void> _approveCoach(String userId) async {
    try {
      await _supabase
          .from('coaches')
          .update({'is_approved': true})
          .eq('user_id', userId);

      await _supabase
          .from('profiles')
          .update({'is_coach': true})
          .eq('id', userId);

      _fetchPendingCoaches();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('مربی با موفقیت تأیید شد')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در تأیید مربی: $e')));
    }
  }

  Future<void> _rejectCoach(String userId) async {
    try {
      await _supabase.from('coaches').delete().eq('user_id', userId);
      _fetchPendingCoaches();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('درخواست مربی رد شد')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در رد درخواست: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تأیید مربی‌ها',
          style: GoogleFonts.vazirmatn(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body:
          _pendingCoaches.isEmpty
              ? Center(
                child: Text(
                  'درخواستی برای تأیید وجود ندارد',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: _pendingCoaches.length,
                itemBuilder: (context, index) {
                  final coach = _pendingCoaches[index];
                  return Card(
                    color: Colors.blueGrey.shade800,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        coach['profiles']['username'] ?? 'نامشخص',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سال تجربه: ${coach['experience_years']}',
                            style: GoogleFonts.vazirmatn(color: Colors.white70),
                          ),
                          Text(
                            'گواهینامه‌ها: ${coach['certifications'].join(', ')}',
                            style: GoogleFonts.vazirmatn(color: Colors.white70),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approveCoach(coach['user_id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectCoach(coach['user_id']),
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

final _supabase = Supabase.instance.client;
