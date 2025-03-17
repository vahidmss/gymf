import 'package:flutter/material.dart';
import 'package:gymf/providers/CoachProvider.dart';
import 'package:gymf/providers/WorkoutPlanProvider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/otp_service.dart';
import '../data/models/user_model.dart';
import '../providers/exercise_provider.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OtpService _otpService = OtpService();

  UserProfileModel? _currentUser;
  bool _isCoach = false;
  bool _isAdmin = false;
  bool _isLoading = false;

  UserProfileModel? get currentUser => _currentUser;
  String? get userId => _supabase.auth.currentUser?.id;
  bool get isCoach => _isCoach;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  String? _otpCode;
  String? get otpCode => _otpCode;

  late StreamSubscription<AuthState> _authSubscription;

  AuthProvider() {
    _listenToAuthState();
  }

  Future<void> initialize() async {
    print('🔄 مقداردهی اولیه AuthProvider...');
    try {
      _isLoading = true;
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
    } catch (e) {
      print('❌ خطا در مقداردهی اولیه AuthProvider: $e');
      throw Exception('خطا در مقداردهی اولیه: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    bool isAuthenticated = false;
    try {
      print('🔄 بررسی وضعیت سشن...');
      _isLoading = true;

      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('🔑 سشن وجود ندارد.');
        _currentUser = null;
        _isCoach = false;
        _isAdmin = false;
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
      print('✅ کاربر با موفقیت بارگذاری شد: ${_currentUser!.username}');
      isAuthenticated = true;
    } catch (e) {
      print('❌ خطا در بررسی وضعیت سشن: $e');
      isAuthenticated = false;
    } finally {
      _isLoading = false;
      // notifyListeners رو اینجا حذف می‌کنیم چون توی فاز ساخت صدا زده می‌شه
    }
    return isAuthenticated;
  }

  Future<void> loadInitialData({
    required ExerciseProvider exerciseProvider,
    required WorkoutPlanProvider workoutPlanProvider,
    required CoachProvider coachProvider,
  }) async {
    try {
      _isLoading = true;
      await exerciseProvider.fetchAllExercises();
      await workoutPlanProvider.fetchCoachPlans(userId ?? '');
      await coachProvider.fetchCoaches();
      print('✅ داده‌های اولیه با موفقیت لود شد.');
    } catch (e) {
      print('❌ خطا در لود داده‌های اولیه: $e');
      throw Exception('خطا در لود داده‌ها: $e');
    } finally {
      _isLoading = false;
      // notifyListeners رو اینجا حذف می‌کنیم
    }
  }

  void setOtpCode(String code) {
    _otpCode = code;
    notifyListeners();
  }

  Future<void> signUpWithPhone(
    String phone,
    String username,
    String password,
    String role,
  ) async {
    try {
      print('🔄 ثبت‌نام با شماره موبایل: $phone');
      _isLoading = true;
      notifyListeners();

      if (!await isUsernameUnique(username)) {
        throw Exception('این یوزرنیم قبلاً استفاده شده است.');
      }

      await _otpService.sendOtp(phone);
      final authResponse = await _supabase.auth.signUp(
        phone: phone,
        password: password,
        data: {'username': username},
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('ثبت‌نام ناموفق بود.');
      }

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String phone, String enteredCode) async {
    try {
      print('🔄 تأیید OTP برای شماره: $phone');
      _isLoading = true;
      notifyListeners();

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      print('🔄 ورود با گوگل...');
      _isLoading = true;
      notifyListeners();

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithUsername(String username, String password) async {
    try {
      print('🔄 ورود با یوزرنیم: $username');
      _isLoading = true;
      notifyListeners();

      final userData = await getUserDataByUsername(username);
      if (userData == null) {
        throw Exception('یوزرنیم اشتباه است.');
      }

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeProfile(String username, String role) async {
    try {
      print('🔄 تکمیل پروفایل برای یوزرنیم: $username');
      _isLoading = true;
      notifyListeners();

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
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> saveUserData(UserProfileModel user) async {
    try {
      print("📌 Data before upsert: ${user.toJson()}");
      await _supabase
          .from('profiles')
          .upsert(user.toJson())
          .timeout(const Duration(seconds: 10));
      print('✅ اطلاعات کاربر با موفقیت ذخیره شد.');
    } catch (e) {
      print('❌ خطا در ذخیره اطلاعات کاربر: $e');
      throw Exception('خطا در ذخیره اطلاعات: $e');
    }
  }

  Future<UserProfileModel?> getUserData(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      return response != null ? UserProfileModel.fromJson(response) : null;
    } catch (e) {
      print('❌ خطا در دریافت اطلاعات کاربر: $e');
      return null;
    }
  }

  Future<UserProfileModel?> getUserDataByUsername(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      return response != null ? UserProfileModel.fromJson(response) : null;
    } catch (e) {
      print('❌ خطا در دریافت اطلاعات کاربر با یوزرنیم: $e');
      return null;
    }
  }

  Future<UserProfileModel?> getUserDataByPhone(String phone) async {
    try {
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
      _isLoading = true;
      notifyListeners();

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
    } finally {
      _isLoading = false;
      notifyListeners();
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
      _currentUser =
          response != null ? UserProfileModel.fromJson(response) : null;
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

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await Supabase.instance.client.auth.signOut();
      _currentUser = null;
      _isCoach = false;
      _isAdmin = false;
      notifyListeners();
      print('✅ با موفقیت خارج شدید.');
    } catch (e) {
      print('❌ خطا در خروج: $e');
      throw Exception('خطا در خروج: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
