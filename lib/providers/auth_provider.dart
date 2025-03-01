import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/otp_service.dart';
import '../data/models/user_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OtpService _otpService = OtpService();
  Future<void> initialize() async {
    if (_supabase.auth.currentSession != null) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        _currentUser = await getUserData(userId);
        notifyListeners();
      }
    }
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  String? get userId => _supabase.auth.currentUser?.id;

  String? _otpCode;
  String? get otpCode => _otpCode;

  late StreamSubscription<AuthState> _authSubscription;

  /// چک کردن وضعیت لاگین کاربر
  Future<bool> checkAuthStatus() async {
    return _supabase.auth.currentSession != null;
  }

  /// تنظیم کد OTP
  void setOtpCode(String code) {
    _otpCode = code;
    notifyListeners();
  }

  /// هش کردن رمز عبور
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// ثبت‌نام با شماره موبایل و OTP
  Future<void> signUpWithPhone(
    String phone,
    String username,
    String password,
    String role,
  ) async {
    try {
      if (!await isUsernameUnique(username)) {
        throw Exception('این یوزرنیم قبلاً استفاده شده است.');
      }

      await _otpService.sendOtp(phone);
      await _supabase.auth.signInWithOtp(phone: phone);

      final hashedPassword = _hashPassword(password);
      final userId = const Uuid().v4();

      _currentUser = UserModel(
        userId: userId,
        phone: phone,
        username: username,
        role: role,
        isVerified: false,
        createdAt: DateTime.now(),
        password: hashedPassword,
      );

      await saveUserData(_currentUser!); // ذخیره موقت در دیتابیس
    } catch (e) {
      throw Exception('خطا در ثبت‌نام: $e');
    }
  }

  /// تأیید OTP و ورود
  Future<void> verifyOtp(String phone, String enteredCode) async {
    try {
      final authResponse = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: enteredCode,
      );

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('تأیید OTP ناموفق بود.');
      }

      _currentUser = await getUserDataByPhone(phone);
      if (_currentUser == null) {
        throw Exception('کاربر یافت نشد.');
      }

      _currentUser = _currentUser!.copyWith(isVerified: true);
      await saveUserData(_currentUser!);

      _otpCode = null;
      notifyListeners();
    } catch (e) {
      throw Exception('خطا در تأیید کد: $e');
    }
  }

  /// ورود با گوگل
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session == null) return;

        final user = session.user;
        final response =
            await _supabase
                .from('users')
                .select()
                .eq('id', user.id)
                .maybeSingle();

        if (response == null ||
            response['username'] == null ||
            response['role'] == null) {
          Navigator.pushReplacementNamed(context, '/complete-profile');
        } else {
          await _loadCurrentUser(user.id);
          Navigator.pushReplacementNamed(context, '/dashboard');
        }

        _authSubscription.cancel();
      });

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'gymf://auth/callback',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("مشکلی پیش آمد. لطفاً دوباره تلاش کنید.")),
      );
    }
  }

  /// ورود با یوزرنیم و پسورد
  Future<void> signInWithUsername(String username, String password) async {
    try {
      final userData = await getUserDataByUsername(username);
      if (userData == null || _hashPassword(password) != userData.password) {
        throw Exception('یوزرنیم یا رمز عبور اشتباه است.');
      }

      final authResponse = await _supabase.auth.signInWithPassword(
        email: '$username@gymf.com', // ایمیل فرضی
        password: password,
      );

      _currentUser = userData;
      notifyListeners();
    } catch (e) {
      throw Exception('خطا در ورود: $e');
    }
  }

  /// تکمیل پروفایل بعد از ورود با گوگل یا OTP
  Future<void> completeProfile(String username, String role) async {
    try {
      if (!await isUsernameUnique(username)) {
        throw Exception('این یوزرنیم قبلاً استفاده شده است.');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('کاربر مقداردهی نشده است.');
      }

      _currentUser ??= UserModel(
        userId: userId,
        phone: '',
        username: username,
        role: role,
        isVerified: true,
        createdAt: DateTime.now(),
        password: '',
      );

      _currentUser = _currentUser!.copyWith(username: username, role: role);
      await saveUserData(_currentUser!);

      notifyListeners();
    } catch (e) {
      throw Exception('خطا در تکمیل پروفایل: $e');
    }
  }

  /// بررسی یکتا بودن یوزرنیم
  Future<bool> isUsernameUnique(String username) async {
    final response =
        await _supabase
            .from('users')
            .select()
            .eq('username', username)
            .maybeSingle();
    return response == null;
  }

  /// ذخیره اطلاعات کاربر در دیتابیس
  Future<void> saveUserData(UserModel user) async {
    print("📌 Data before upsert: ${user.toMap()}");
    await _supabase.from('users').upsert(user.toMap());
  }

  /// دریافت اطلاعات کاربر با `userId`
  Future<UserModel?> getUserData(String userId) async {
    final response =
        await _supabase.from('users').select().eq('id', userId).maybeSingle();
    return response != null ? UserModel.fromMap(response) : null;
  }

  /// دریافت اطلاعات کاربر با `username`
  Future<UserModel?> getUserDataByUsername(String username) async {
    final response =
        await _supabase
            .from('users')
            .select()
            .eq('username', username)
            .maybeSingle();
    return response != null ? UserModel.fromMap(response) : null;
  }

  /// دریافت اطلاعات کاربر با شماره موبایل
  Future<UserModel?> getUserDataByPhone(String phone) async {
    final response =
        await _supabase.from('users').select().eq('phone', phone).maybeSingle();
    return response != null ? UserModel.fromMap(response) : null;
  }

  /// تازه‌سازی اطلاعات کاربر
  Future<void> refreshUser() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadCurrentUser(session.user.id);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  /// گوش دادن به تغییرات وضعیت تأیید هویت
  void _listenToAuthState() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _loadCurrentUser(session.user.id);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// لود اطلاعات کاربر با `userId`
  Future<void> _loadCurrentUser(String userId) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
      _currentUser = response != null ? UserModel.fromMap(response) : null;
      notifyListeners();
    } catch (e) {
      print('خطا در لود کاربر: $e');
    }
  }

  /// منتظر ماندن برای تکمیل ورود
  Future<void> _waitForUser() async {
    int retries = 20;
    while (_supabase.auth.currentUser == null && retries > 0) {
      await Future.delayed(const Duration(milliseconds: 800));
      retries--;
    }
  }

  /// لغو `StreamSubscription` برای جلوگیری از نشت حافظه
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
