import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpService {
  static const String apiKey = '04cce60c3b6c447783c27264975f4580';

  Future<String> sendOtp(String phone) async {
    if (!isValidIranianPhoneNumber(phone)) {
      throw Exception(
        'شماره موبایل نامعتبر است. لطفاً شماره‌ای با فرمت 09XXXXXXXXX وارد کنید.',
      );
    }

    final formattedPhone = phone.startsWith('09') ? phone : '0$phone';

    final response = await http.post(
      Uri.parse('https://console.melipayamak.com/api/send/otp/$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'to': formattedPhone}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' || data['status'].isEmpty) {
        return data['code'];
      } else {
        throw Exception('Failed to send OTP: ${data['status']}');
      }
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  bool isValidIranianPhoneNumber(String phone) {
    if (phone.length == 11 && phone.startsWith('09')) {
      return RegExp(r'^[0-9]+$').hasMatch(phone);
    } else if (phone.length == 12 && phone.startsWith('+989')) {
      return RegExp(r'^\+989[0-9]{9}$').hasMatch(phone);
    }
    return false;
  }
}
