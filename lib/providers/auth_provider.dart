import 'package:flutter/material.dart';
import 'package:gymf/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/otp_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OtpService _otpService = OtpService();
  final Uuid _uuid = const Uuid();

  UserModel? _currentUser;
  bool _isCoach = false; // اضافه کردن برای نقش مربی
  bool _isAdmin = false; // اضافه کردن برای نقش ادمین

  UserModel? get currentUser => _currentUser;
  String? get userId => _supabase.auth.currentUser?.id;
  bool get isCoach => _isCoach; // گتر برای نقش مربی
  bool get isAdmin => _isAdmin; // گتر برای نقش ادمین

  String? _otpCode;
  String? get otpCode => _otpCode;

  late StreamSubscription<AuthState> _authSubscription;

  AuthProvider() {
    _listenToAuthState();
  }

  Future<void> initialize() async {
    print('🔄 مقداردهی اولیه AuthProvider...');
    try {
      if (_supabase.auth.currentSession != null) {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          print('🔑 سشن موجود است، بارگذاری اطلاعات کاربر با ID: $userId');
          _currentUser = await getUserData(userId);
          if (_currentUser != null) {
            _isCoach = _currentUser!.isCoach;
            _isAdmin = _currentUser!.isAdmin;
            print('✅ کاربر با موفقیت بارگذاری شد: ${_currentUser!.username}');
          } else {
            print(
              '⚠️ کاربر در دیتابیس یافت نشد، ممکن است نیاز به تکمیل پروفایل داشته باشد.',
            );
          }
        } else {
          print('⚠️ سشن وجود دارد اما userId یافت نشد.');
        }
      } else {
        print('🔑 سشن وجود ندارد، کاربر وارد نشده است.');
      }
      notifyListeners();
    } catch (e) {
      print('❌ خطا در مقداردهی اولیه AuthProvider: $e');
    }
  }

  Future<bool> checkAuthStatus() async {
    try {
      print('🔄 بررسی وضعیت سشن...');
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('🔑 سشن وجود ندارد.');
        _currentUser = null;
        _isCoach = false;
        _isAdmin = false;
        notifyListeners();
        return false;
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ سشن وجود دارد اما userId یافت نشد.');
        return false;
      }

      print('✅ سشن معتبر است، userId: $userId');
      _currentUser = await getUserData(userId);
      if (_currentUser == null) {
        print(
          '⚠️ کاربر در دیتابیس یافت نشد، ممکن است نیاز به تکمیل پروفایل داشته باشد.',
        );
        return false;
      }

      _isCoach = _currentUser!.isCoach;
      _isAdmin = _currentUser!.isAdmin;
      notifyListeners();
      print('✅ کاربر با موفقیت بارگذاری شد: ${_currentUser!.username}');
      return true;
    } catch (e) {
      print('❌ خطا در بررسی وضعیت سشن: $e');
      return false;
    }
  }

  void setOtpCode(String code) {
    _otpCode = code;
    notifyListeners();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> signUpWithPhone(
    String phone,
    String username,
    String password,
    String role,
  ) async {
    try {
      print('🔄 ثبت‌نام با شماره موبایل: $phone');
      if (!await isUsernameUnique(username)) {
        throw Exception('این یوزرنیم قبلاً استفاده شده است.');
      }

      await _otpService.sendOtp(phone);
      // ثبت‌نام با OTP و ارسال username در options.data
      final authResponse = await _supabase.auth.signUp(
        phone: phone,
        password: _hashPassword(password), // استفاده از رمز عبور هش‌شده
        data: {'username': username}, // برای ذخیره خودکار در profiles
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('ثبت‌نام ناموفق بود.');
      }

      // چون تریگر create_profile_for_new_user داریم، پروفایل خودکار ساخته می‌شه
      // فقط باید نقش‌ها رو آپدیت کنیم
      await _supabase
          .from('profiles')
          .update({
            'is_coach': role.toLowerCase() == 'coach',
            'is_admin': role.toLowerCase() == 'admin',
          })
          .eq('id', user.id);

      _currentUser = await getUserData(user.id);
      if (_currentUser == null) {
        throw Exception('کاربر در دیتابیس یافت نشد.');
      }

      _isCoach = _currentUser!.isCoach;
      _isAdmin = _currentUser!.isAdmin;
      notifyListeners();
      print('✅ کاربر با موفقیت ثبت شد: $username');
    } catch (e) {
      print('❌ خطا در ثبت‌نام: $e');
      throw Exception('خطا در ثبت‌نام: $e');
    }
  }

  Future<void> verifyOtp(String phone, String enteredCode) async {
    try {
      print('🔄 تأیید OTP برای شماره: $phone');
      final authResponse = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: enteredCode,
      );

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('تأیید OTP ناموفق بود.');
      }

      _currentUser = await getUserData(user.id);
      if (_currentUser == null) {
        throw Exception('کاربر یافت نشد.');
      }

      _isCoach = _currentUser!.isCoach;
      _isAdmin = _currentUser!.isAdmin;
      _otpCode = null;
      notifyListeners();
      print('✅ OTP با موفقیت تأیید شد.');
    } catch (e) {
      print('❌ خطا در تأیید کد: $e');
      throw Exception('خطا در تأیید کد: $e');
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      print('🔄 ورود با گوگل...');
      _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session == null) return;

        final user = session.user;
        final response =
            await _supabase
                .from('profiles')
                .select()
                .eq('id', user.id)
                .maybeSingle();

        if (response == null || response['username'] == null) {
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
      print('❌ خطا در ورود با گوگل: $e');
      throw Exception('خطا در ورود با گوگل: $e');
    }
  }

  Future<void> signInWithUsername(String username, String password) async {
    try {
      print('🔄 ورود با یوزرنیم: $username');
      final userData = await getUserDataByUsername(username);
      if (userData == null) {
        throw Exception('یوزرنیم یا رمز عبور اشتباه است.');
      }

      // چون رمز عبور توی Supabase Auth ذخیره می‌شه، باید با Supabase Auth ورود کنیم
      // ورود با ایمیل یا شماره (بسته به اینکه کاربر با چی ثبت‌نام کرده)
      final email = userData.email;
      if (email == null || email.isEmpty) {
        throw Exception('ایمیل کاربر یافت نشد، لطفاً با گوگل وارد شوید.');
      }

      await _supabase.auth.signInWithPassword(email: email, password: password);

      _currentUser = userData;
      _isCoach = _currentUser!.isCoach;
      _isAdmin = _currentUser!.isAdmin;
      notifyListeners();
      print('✅ ورود با موفقیت انجام شد.');
    } catch (e) {
      print('❌ خطا در ورود: $e');
      throw Exception('خطا در ورود: $e');
    }
  }

  Future<void> completeProfile(String username, String role) async {
    try {
      print('🔄 تکمیل پروفایل برای یوزرنیم: $username');
      if (!await isUsernameUnique(username)) {
        throw Exception('این یوزرنیم قبلاً استفاده شده است.');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('کاربر مقداردهی نشده است.');
      }

      await _supabase
          .from('profiles')
          .update({
            'username': username,
            'is_coach': role.toLowerCase() == 'coach',
            'is_admin': role.toLowerCase() == 'admin',
          })
          .eq('id', userId);

      _currentUser = await getUserData(userId);
      if (_currentUser == null) {
        throw Exception('کاربر یافت نشد.');
      }

      _isCoach = _currentUser!.isCoach;
      _isAdmin = _currentUser!.isAdmin;
      notifyListeners();
      print('✅ پروفایل با موفقیت تکمیل شد.');
    } catch (e) {
      print('❌ خطا در تکمیل پروفایل: $e');
      throw Exception('خطا در تکمیل پروفایل: $e');
    }
  }

  Future<bool> isUsernameUnique(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      return response == null;
    } catch (e) {
      print('❌ خطا در بررسی یوزرنیم: $e');
      throw Exception('خطا در بررسی یوزرنیم: $e');
    }
  }

  Future<void> saveUserData(UserModel user) async {
    try {
      print("📌 Data before upsert: ${user.toMap()}");
      await _supabase
          .from('profiles')
          .upsert(user.toMap())
          .timeout(const Duration(seconds: 10));
      print('✅ اطلاعات کاربر با موفقیت ذخیره شد.');
    } catch (e) {
      print('❌ خطا در ذخیره اطلاعات کاربر: $e');
      throw Exception('خطا در ذخیره اطلاعات: $e');
    }
  }

  Future<UserModel?> getUserData(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      return response != null ? UserModel.fromMap(response) : null;
    } catch (e) {
      print('❌ خطا در دریافت اطلاعات کاربر: $e');
      return null;
    }
  }

  Future<UserModel?> getUserDataByUsername(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      return response != null ? UserModel.fromMap(response) : null;
    } catch (e) {
      print('❌ خطا در دریافت اطلاعات کاربر با یوزرنیم: $e');
      return null;
    }
  }

  Future<UserModel?> getUserDataByPhone(String phone) async {
    try {
      // چون شماره تلفن توی auth.users ذخیره می‌شه، باید از اونجا بگیریم
      final user = _supabase.auth.currentUser;
      if (user == null || user.phone != phone) {
        return null;
      }
      return await getUserData(user.id);
    } catch (e) {
      print('❌ خطا در دریافت اطلاعات کاربر با شماره: $e');
      return null;
    }
  }

  Future<void> refreshUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadCurrentUser(session.user.id);
      } else {
        _currentUser = null;
        _isCoach = false;
        _isAdmin = false;
        notifyListeners();
      }
    } catch (e) {
      print('❌ خطا در تازه‌سازی اطلاعات کاربر: $e');
    }
  }

  void _listenToAuthState() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      print('🔄 تغییر وضعیت احراز هویت: ${data.event}');
      final session = data.session;
      if (session != null) {
        await _loadCurrentUser(session.user.id);
      } else {
        _currentUser = null;
        _isCoach = false;
        _isAdmin = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadCurrentUser(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      _currentUser = response != null ? UserModel.fromMap(response) : null;
      if (_currentUser != null) {
        _isCoach = _currentUser!.isCoach;
        _isAdmin = _currentUser!.isAdmin;
      } else {
        _isCoach = false;
        _isAdmin = false;
      }
      notifyListeners();
      print('✅ کاربر بارگذاری شد: ${_currentUser?.username}');
    } catch (e) {
      print('❌ خطا در لود کاربر: $e');
    }
  }

  Future<void> _waitForUser() async {
    int retries = 20;
    while (_supabase.auth.currentUser == null && retries > 0) {
      await Future.delayed(const Duration(milliseconds: 800));
      retries--;
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    _isCoach = false;
    _isAdmin = false;
    notifyListeners();
  }
}
