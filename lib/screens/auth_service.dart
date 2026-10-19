import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3.x: StateProvider artık legacy.dart içinde.
import 'package:flutter_riverpod/legacy.dart';

/// Dosya yolu: lib/screens/auth_service.dart
///
/// Giriş: E-POSTA + ŞİFRE (Firebase e-posta/şifre girişi).
/// Telefon numarası kayıtta isteğe bağlı olarak profile yazılır.

/// Oturum durumu (null = giriş yapılmamış)
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// Kullanıcı giriş yapmış mı?
final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).value != null,
);

/// "Üye olmadan devam et" seçildi mi?
final guestModeProvider = StateProvider<bool>((ref) => false);

/// Giriş veya Kayıt ekranının ekranda aktif olup olmadığını takip eder
final authScreenVisibleProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 0555 123 45 67 / +90 555 123 45 67 / 5551234567 → "5551234567"
/// Geçersizse null döner.
String? normalizePhone(String raw) {
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 12 && d.startsWith('90')) d = d.substring(2);
  if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
  if (d.length == 10 && d.startsWith('5')) return d;
  return null;
}

bool isValidEmail(String s) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s.trim());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> signIn(String email, String password) async {
    final e = email.trim();
    if (!isValidEmail(e)) throw const FormatException('email');
    await _auth.signInWithEmailAndPassword(email: e, password: password);
  }

  /// Şifre sıfırlama bağlantısını e-postaya gönderir.
  Future<void> sendReset(String email) async {
    final e = email.trim();
    if (!isValidEmail(e)) throw const FormatException('email');
    await _auth.sendPasswordResetEmail(email: e);
  }

  /// Hesabı oluşturur ve kullanıcıyı Firestore `users/{uid}` altına kaydeder.
  Future<void> register({
    required String fullName,
    required String email,
    required String phone, // boş olabilir
    required String neighborhood,
    required String password,
    String language = 'tr',
  }) async {
    final mail = email.trim();
    if (!isValidEmail(mail)) throw const FormatException('email');
    final p = phone.trim().isEmpty ? null : normalizePhone(phone);
    if (phone.trim().isNotEmpty && p == null) {
      throw const FormatException('phone');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: mail,
      password: password,
    );
    final user = cred.user!;
    try {
      await user.updateDisplayName(fullName.trim());
    } catch (_) {}

    // Firestore yazımı başarısız olsa bile hesap oluşmuştur; kayıt hatası
    // gösterme (kurallar yüzünden "hata oluştu" deyip oturum açık kalıyordu).
    try {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': mail,
        'phoneNumber': p == null ? '' : '0$p',
        'neighborhood': neighborhood,
        'address': '',
        'tcNo': '',
        'avatarUrl': '',
        'isVerified': false,
        'language': language,
        'themeMode': 'light',
        'largeFont': false,
        'notificationPreferences': {
          'push': true,
          'sms': true,
          'outages': true,
          'emergency': true,
          'sozSende': true,
        },
        'totalSuggestions': 0,
        'totalSupported': 0,
        'totalSaved': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> signOut() => _auth.signOut();
}

/// Hatayı metin anahtarına çevirir.
String authErrorKey(Object e) {
  if (e is FormatException && e.message == 'phone') return 'err_phone';
  if (e is FormatException && e.message == 'email') return 'err_email';
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'err_invalid';
      case 'invalid-email':
        return 'err_email';
      case 'email-already-in-use':
        return 'err_exists';
      case 'weak-password':
        return 'err_weak';
      case 'operation-not-allowed':
        return 'err_disabled';
      case 'network-request-failed':
        return 'err_network';
      case 'too-many-requests':
        return 'err_many';
    }
  }
  return 'err_generic';
}

/// Auth ekranlarının metinleri (tr / en / ar). Bulunamazsa tr'ye düşer.
String at(String lang, String key) => _s[lang]?[key] ?? _s['tr']![key] ?? key;

const Map<String, Map<String, String>> _s = {
  'tr': {
    'email': 'E-posta',
    'email_hint': 'ornek@mail.com',
    'send': 'Gönder',
    'optional': 'isteğe bağlı',
    'err_email': 'Geçerli bir e-posta adresi girin.',
    'reset_sent': 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
    'login_title': 'ÜYE GİRİŞ EKRANI',
    'phone': 'Telefon Numarası',
    'phone_hint': '05XX XXX XX XX',
    'password': 'Şifre',
    'forgot': 'Şifremi Unuttum ?',
    'forgot_title': 'Şifremi Unuttum',
    'forgot_msg': 'Kayıtlı e-posta adresinizi yazın, şifre sıfırlama bağlantısı gönderelim.',
    'call': 'Ara',
    'close': 'Kapat',
    'login': 'Giriş Yap',
    'or': 'YA DA',
    'go_register': 'Üye olmak için tıklayınız.',
    'guest': 'Üye Olmadan Devam Et',
    'register_title': 'KAYIT OL',
    'full_name': 'Ad Soyad',
    'neighborhood': 'Mahalle',
    'password2': 'Şifre (Tekrar)',
    'kvkk': 'KVKK aydınlatma metnini okudum, kabul ediyorum.',
    'create': 'Kayıt Ol',
    'have_account': 'Zaten üyeyim, giriş yap',
    'gate_title': 'Üyelik Gerekli',
    'gate_msg': 'Bu bölüme girmek için üye olmanız gerekmektedir.',
    'cancel': 'Vazgeç',
    'gate_go': 'Giriş Yap / Kayıt Ol',
    'err_required': 'Lütfen tüm alanları doldurun.',
    'err_phone': 'Geçerli bir cep telefonu girin (05XX XXX XX XX).',
    'err_match': 'Şifreler eşleşmiyor.',
    'err_kvkk': 'Devam etmek için KVKK onayı gereklidir.',
    'err_invalid': 'E-posta veya şifre hatalı.',
    'err_exists': 'Bu e-posta ile zaten bir hesap var.',
    'err_weak': 'Şifre en az 6 karakter olmalıdır.',
    'err_disabled': 'Giriş yöntemi kapalı. (Firebase > Authentication > E-posta/Şifre açılmalı)',
    'err_network': 'Bağlantı hatası. İnternetinizi kontrol edin.',
    'err_many': 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.',
    'err_generic': 'Bir hata oluştu. Lütfen tekrar deneyin.',
  },
  'en': {
    'email': 'Email',
    'email_hint': 'example@mail.com',
    'send': 'Send',
    'optional': 'optional',
    'err_email': 'Enter a valid email address.',
    'reset_sent': 'A password reset link has been sent to your email.',
    'login_title': 'MEMBER LOGIN',
    'phone': 'Phone Number',
    'phone_hint': '05XX XXX XX XX',
    'password': 'Password',
    'forgot': 'Forgot password ?',
    'forgot_title': 'Forgot Password',
    'forgot_msg':
        'Enter your registered email and we will send you a reset link.',
    'call': 'Call',
    'close': 'Close',
    'login': 'Log In',
    'or': 'OR',
    'go_register': 'Tap here to create an account.',
    'guest': 'Continue Without Signing Up',
    'register_title': 'SIGN UP',
    'full_name': 'Full Name',
    'neighborhood': 'Neighborhood',
    'password2': 'Confirm Password',
    'kvkk': 'I have read and accept the privacy notice (KVKK).',
    'create': 'Sign Up',
    'have_account': 'I already have an account, log in',
    'gate_title': 'Membership Required',
    'gate_msg': 'You need to be a member to access this section.',
    'cancel': 'Cancel',
    'gate_go': 'Log In / Sign Up',
    'err_required': 'Please fill in all fields.',
    'err_phone': 'Enter a valid mobile number (05XX XXX XX XX).',
    'err_match': 'Passwords do not match.',
    'err_kvkk': 'You must accept the privacy notice to continue.',
    'err_invalid': 'Incorrect email or password.',
    'err_exists': 'An account with this email already exists.',
    'err_weak': 'Password must be at least 6 characters.',
    'err_disabled': 'Sign-in method is disabled in Firebase.',
    'err_network': 'Connection error. Check your internet.',
    'err_many': 'Too many attempts. Try again later.',
    'err_generic': 'Something went wrong. Please try again.',
  },
  'ar': {
    'email': 'البريد الإلكتروني',
    'email_hint': 'example@mail.com',
    'send': 'إرسال',
    'optional': 'اختياري',
    'err_email': 'أدخل بريداً إلكترونياً صالحاً.',
    'reset_sent': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.',
    'login_title': 'شاشة تسجيل دخول الأعضاء',
    'phone': 'رقم الهاتف',
    'phone_hint': '05XX XXX XX XX',
    'password': 'كلمة المرور',
    'forgot': 'نسيت كلمة المرور ؟',
    'forgot_title': 'نسيت كلمة المرور',
    'forgot_msg': 'اكتب بريدك الإلكتروني المسجل وسنرسل لك رابط إعادة التعيين.',
    'call': 'اتصال',
    'close': 'إغلاق',
    'login': 'تسجيل الدخول',
    'or': 'أو',
    'go_register': 'اضغط هنا لإنشاء حساب.',
    'guest': 'المتابعة بدون عضوية',
    'register_title': 'إنشاء حساب',
    'full_name': 'الاسم الكامل',
    'neighborhood': 'الحي',
    'password2': 'تأكيد كلمة المرور',
    'kvkk': 'قرأت إشعار الخصوصية (KVKK) وأوافق عليه.',
    'create': 'إنشاء حساب',
    'have_account': 'لدي حساب بالفعل، تسجيل الدخول',
    'gate_title': 'العضوية مطلوبة',
    'gate_msg': 'يجب أن تكون عضواً للدخول إلى هذا القسم.',
    'cancel': 'إلغاء',
    'gate_go': 'تسجيل الدخول / إنشاء حساب',
    'err_required': 'يرجى ملء جميع الحقول.',
    'err_phone': 'أدخل رقم هاتف محمول صالحاً (05XX XXX XX XX).',
    'err_match': 'كلمتا المرور غير متطابقتين.',
    'err_kvkk': 'يجب الموافقة على إشعار الخصوصية للمتابعة.',
    'err_invalid': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'err_exists': 'يوجد حساب بهذا البريد بالفعل.',
    'err_weak': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.',
    'err_disabled': 'طريقة تسجيل الدخول معطلة في Firebase.',
    'err_network': 'خطأ في الاتصال. تحقق من الإنترنت.',
    'err_many': 'محاولات كثيرة. حاول لاحقاً.',
    'err_generic': 'حدث خطأ. يرجى المحاولة مرة أخرى.',
  },
};
