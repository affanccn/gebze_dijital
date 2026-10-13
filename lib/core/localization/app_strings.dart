import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'tr';

  void setLanguage(String lang) {
    state = lang;
  }

  @override
  set state(String value) {
    super.state = value;
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, String>(AppLanguageNotifier.new);

class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    // ───────────────────────── Alt Menü (Bottom Nav) ─────────────────────────
    'nav_home': {
      'tr': 'ANA SAYFA',
      'en': 'HOME',
      'ar': 'الرئيسية',
    },
    'nav_guide': {
      'tr': 'REHBER',
      'en': 'GUIDE',
      'ar': 'دليل',
    },
    'nav_report': {
      'tr': 'BİLDİR',
      'en': 'REPORT',
      'ar': 'إبلاغ',
    },
    'nav_services': {
      'tr': 'HİZMETLER',
      'en': 'SERVICES',
      'ar': 'الخدمات',
    },
    'nav_profile': {
      'tr': 'PROFİL',
      'en': 'PROFILE',
      'ar': 'الملف الشخصي',
    },

    // ───────────────────────── Ana Sayfa ─────────────────────────
    'welcome_gebze': {
      'tr': "Gebze'ye\nHoşgeldiniz",
      'en': "Welcome to\nGebze",
      'ar': "مرحباً بكم في\nجبزة",
    },
    'better_gebze': {
      'tr': "Daha güzel\nbir Gebze için",
      'en': "For a better\nGebze",
      'ar': "من أجل جبزة\nأفضل",
    },
    'emergency_btn': {
      'tr': 'ACİL\nDURUM',
      'en': 'EMERGENCY',
      'ar': 'حالة\nطوارئ',
    },
    'quick_actions_title': {
      'tr': 'HIZLI İŞLEMLER',
      'en': 'QUICK ACTIONS',
      'ar': 'إجراءات سريعة',
    },
    'events_title': {
      'tr': 'YAKLAŞAN ETKİNLİKLER',
      'en': 'UPCOMING EVENTS',
      'ar': 'الفعاليات القادمة',
    },
    'historic_places_title': {
      'tr': 'TARİHİ YERLER',
      'en': 'HISTORIC PLACES',
      'ar': 'أماكن تاريخية',
    },
    'news_title': {
      'tr': 'Gebze Haberleri',
      'en': 'Gebze News',
      'ar': 'أخبار جبزة',
    },
    'see_all': {
      'tr': 'Tümünü Gör',
      'en': 'See All',
      'ar': 'عرض الكل',
    },
    'current_weather_pill': {
      'tr': 'Güncel Hava Durumu',
      'en': 'Current Weather',
      'ar': 'الطقس الحالي',
    },

    'qa_places': {
      'tr': 'GEZİLECEK YER',
      'en': 'ATTRACTIONS',
      'ar': 'معالم سياحية',
    },
    'qa_food': {
      'tr': 'YEME İÇME',
      'en': 'FOOD & DRINK',
      'ar': 'طعام وشراب',
    },
    'qa_ebel': {
      'tr': 'E-BEL',
      'en': 'E-MUN',
      'ar': 'البلدية',
    },
    'qa_complaint': {
      'tr': 'MİSAFİR ŞİKAYET',
      'en': 'GUEST REPORT',
      'ar': 'شكاوى الزوار',
    },
    'qa_parking': {
      'tr': 'OTOPARK',
      'en': 'PARKING',
      'ar': 'مواقف السيارات',
    },
    'loading': {
      'tr': 'Yükleniyor...',
      'en': 'Loading...',
      'ar': 'جاري التحميل...',
    },
    'failed_to_load': {
      'tr': 'Alınamadı',
      'en': 'Unavailable',
      'ar': 'تعذر التحميل',
    },
    'coming_soon': {
      'tr': 'yakında',
      'en': 'coming soon',
      'ar': 'قريباً',
    },
    'service_emergency': {
      'tr': 'ACİL DURUM',
      'en': 'EMERGENCY',
      'ar': 'حالة طوارئ',
    },
    'service_emergency_sub': {
      'tr': 'Acil numaralar ve tek dokunuşla yardım çağır',
      'en': 'Emergency numbers and instant help',
      'ar': 'أرقام الطوارئ وطلب المساعدة بلمسة واحدة',
    },
    'service_news': {
      'tr': 'Haberler & Duyurular',
      'en': 'News & Announcements',
      'ar': 'الأخبار والإعلانات',
    },
    'service_news_sub': {
      'tr': 'Güncel belediye bültenleri ve ilanlar',
      'en': 'Municipal news bulletins and announcements',
      'ar': 'نشرات البلدية والإعلانات الحديثة',
    },
    'lang_tr_selected': {
      'tr': 'Uygulama dili Türkçe olarak seçildi.',
      'en': 'Language set to Turkish.',
      'ar': 'تم ضبط لغة التطبيق إلى التركية.',
    },
    'lang_en_selected': {
      'tr': 'Uygulama dili İngilizce olarak seçildi.',
      'en': 'Application language set to English.',
      'ar': 'تم ضبط لغة التطبيق إلى الإنجليزية.',
    },
    'lang_ar_selected': {
      'tr': 'Uygulama dili Arapça olarak seçildi.',
      'en': 'Application language set to Arabic.',
      'ar': 'تم ضبط لغة التطبيق إلى العربية.',
    },
    'mahalle_suffix': {
      'tr': 'Mahallesi',
      'en': 'Neighborhood',
      'ar': 'حي',
    },
    'mahalle_abbr': {
      'tr': 'Mah.',
      'en': 'Dist.',
      'ar': 'حي',
    },
    'confirm_signout_msg': {
      'tr': 'Mevcut oturumunuzu kapatmak istediğinize emin misiniz?',
      'en': 'Are you sure you want to log out?',
      'ar': 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
    },
    'logged_out_msg': {
      'tr': 'Oturum kapatıldı.',
      'en': 'Logged out successfully.',
      'ar': 'تم تسجيل الخروج بنجاح.',
    },
    'confirm_delete_msg': {
      'tr': 'Hesabınızı silmek üzeresiniz. Bu işlem geri alınamaz ve belediyemizdeki tüm talepleriniz arşivlenir. Devam etmek istiyor musunuz?',
      'en': 'You are about to delete your account. This action cannot be undone. Do you wish to proceed?',
      'ar': 'أنت على وشك حذف حسابك. هذا الإجراء لا يمكن التراجع عنه. هل ترغب في المتابعة؟',
    },
    'account_deleted_msg': {
      'tr': 'Hesabınız başarıyla silindi.',
      'en': 'Your account has been deleted.',
      'ar': 'تم حذف حسابك بنجاح.',
    },
    'dismiss': {
      'tr': 'Vazgeç',
      'en': 'Dismiss',
      'ar': 'تراجع',
    },

    // ───────────────────────── Hizmetler ─────────────────────────
    'services_screen_title': {
      'tr': 'HİZMETLER',
      'en': 'SERVICES',
      'ar': 'الخدمات',
    },
    'services_screen_subtitle': {
      'tr': 'Gebze Belediyesi dijital hizmetleri',
      'en': 'Gebze Municipality digital services',
      'ar': 'خدمات بلدية جبزة الرقمية',
    },
    'search_services_hint': {
      'tr': 'Hizmet veya işlem ara...',
      'en': 'Search services or actions...',
      'ar': 'بحث عن الخدمات أو المعاملات...',
    },
    'service_outages': {
      'tr': 'Kesintiler',
      'en': 'Outages',
      'ar': 'الانقطاعات',
    },
    'service_outages_sub': {
      'tr': 'Su, elektrik ve doğalgaz kesintileri',
      'en': 'Water, electricity and gas outages',
      'ar': 'انقطاع المياه والكهرباء والغاز',
    },
    'service_parking': {
      'tr': 'Otopark',
      'en': 'Parking',
      'ar': 'مواقف السيارات',
    },
    'service_parking_sub': {
      'tr': 'Boş park yerleri ve ücretler',
      'en': 'Empty parking spots and fees',
      'ar': 'المواقف الشاغرة والرسوم',
    },
    'service_soz_sende': {
      'tr': 'Söz Sende',
      'en': 'Your Say',
      'ar': 'الرأي لك',
    },
    'service_soz_sende_sub': {
      'tr': 'Fikir, öneri ve oylamalar',
      'en': 'Ideas, suggestions and votes',
      'ar': 'الأفكار والمقترحات والتصويت',
    },
    'service_pati': {
      'tr': 'Gebze Pati',
      'en': 'Gebze Paws',
      'ar': 'رعاية الحيوانات',
    },
    'service_pati_sub': {
      'tr': 'Sahiplendirme ve sokak hayvanları',
      'en': 'Adoption and street animals',
      'ar': 'التبني وحيوانات الشارع',
    },
    'service_pharmacy': {
      'tr': 'Nöbetçi Eczane',
      'en': 'Pharmacies on Duty',
      'ar': 'الصيدليات المناوبة',
    },
    'service_pharmacy_sub': {
      'tr': 'Bugün nöbetçi olan eczaneler',
      'en': 'Pharmacies on duty today',
      'ar': 'الصيدليات المناوبة اليوم',
    },
    'service_weather': {
      'tr': 'Hava Durumu',
      'en': 'Weather',
      'ar': 'الطقس',
    },
    'service_weather_sub': {
      'tr': 'Anlık durum ve haftalık tahmin',
      'en': 'Current conditions & weekly forecast',
      'ar': 'الطقس الحالي والتوقعات الأسبوعية',
    },
    'service_neighborhood': {
      'tr': 'Mahallemde',
      'en': 'My Neighborhood',
      'ar': 'في حيي',
    },
    'service_neighborhood_sub': {
      'tr': 'Mahallendeki çalışmalar ve hizmetler',
      'en': 'Works and services in your neighborhood',
      'ar': 'الأعمال والخدمات في حيك',
    },
    'service_ebelediye': {
      'tr': 'E-Belediye',
      'en': 'E-Municipality',
      'ar': 'البلدية الإلكترونية',
    },
    'service_ebelediye_sub': {
      'tr': 'Borç sorgulama ve online işlemler',
      'en': 'Debt inquiry and online operations',
      'ar': 'الاستعلام عن الديون والمعاملات عبر الإنترنت',
    },

    // ───────────────────────── Hava Durumu ─────────────────────────
    'weather_screen_title': {
      'tr': 'HAVA DURUMU',
      'en': 'WEATHER',
      'ar': 'الطقس',
    },
    'weather_screen_sub': {
      'tr': 'Gebze için anlık hava durumu ve 5 günlük tahmin raporu.',
      'en': 'Live weather and 5-day forecast report for Gebze.',
      'ar': 'تقرير الطقس اللحظي وتوقعات 5 أيام لمدينة جبزة.',
    },
    'feels_like': {
      'tr': 'Hissedilen',
      'en': 'Feels like',
      'ar': 'المحسوس',
    },
    'humidity': {
      'tr': 'Nem',
      'en': 'Humidity',
      'ar': 'الرطوبة',
    },
    'wind': {
      'tr': 'Rüzgar',
      'en': 'Wind',
      'ar': 'الرياح',
    },
    'hourly_forecast': {
      'tr': 'Saatlik Tahmin',
      'en': 'Hourly Forecast',
      'ar': 'التوقعات بالساعة',
    },
    'five_day_forecast': {
      'tr': '5 Günlük Hava Tahmini',
      'en': '5-Day Weather Forecast',
      'ar': 'توقعات الطقس لخمسة أيام',
    },
    'now': {
      'tr': 'Şimdi',
      'en': 'Now',
      'ar': 'الآن',
    },
    'today': {
      'tr': 'Bugün',
      'en': 'Today',
      'ar': 'اليوم',
    },
    'tomorrow': {
      'tr': 'Yarın',
      'en': 'Tomorrow',
      'ar': 'غداً',
    },
    'gebze_location': {
      'tr': 'Gebze, Kocaeli',
      'en': 'Gebze, Kocaeli',
      'ar': 'جبزة، قوجا إيلي',
    },
    'current_condition': {
      'tr': 'Güncel Durum',
      'en': 'Current Status',
      'ar': 'الحالة الحالية',
    },
    'last_updated': {
      'tr': 'Son güncelleme',
      'en': 'Last updated',
      'ar': 'آخر تحديث',
    },
    'error_occurred': {
      'tr': 'Bir Hata Oluştu',
      'en': 'An Error Occurred',
      'ar': 'حدث خطأ',
    },

    // ───────────────────────── Profil ─────────────────────────
    'profile_screen_title': {
      'tr': 'PROFİLİM',
      'en': 'MY PROFILE',
      'ar': 'ملفي الشخصي',
    },
    'hello': {
      'tr': 'Merhaba,',
      'en': 'Hello,',
      'ar': 'مرحباً،',
    },
    'verified_badge': {
      'tr': 'Doğrulanmış',
      'en': 'Verified',
      'ar': 'تم التحقق',
    },
    'stat_requests': {
      'tr': 'Taleplerim',
      'en': 'My Requests',
      'ar': 'طلباتي',
    },
    'stat_suggestions': {
      'tr': 'Önerilerim',
      'en': 'My Suggestions',
      'ar': 'اقتراحاتي',
    },
    'stat_supports': {
      'tr': 'Desteklerim',
      'en': 'My Supports',
      'ar': 'دعمي',
    },
    'stat_saved': {
      'tr': 'Kayıtlarım',
      'en': 'Saved',
      'ar': 'محفوظاتي',
    },
    'section_account': {
      'tr': 'HESAP BİLGİLERİ',
      'en': 'ACCOUNT INFO',
      'ar': 'معلومات الحساب',
    },
    'tile_my_info': {
      'tr': 'Bilgilerim',
      'en': 'My Details',
      'ar': 'معلوماتي',
    },
    'tile_neighborhood': {
      'tr': 'Mahalle Seçimi',
      'en': 'Neighborhood Selection',
      'ar': 'اختيار الحي',
    },
    'tile_notifications': {
      'tr': 'Bildirim Tercihleri',
      'en': 'Notification Preferences',
      'ar': 'تفضيلات الإشعارات',
    },
    'tile_notifications_sub': {
      'tr': 'Push, SMS, kesinti ve acil durum uyarıları',
      'en': 'Push, SMS, outage and emergency alerts',
      'ar': 'تنبيهات الإشعارات، والرسائل، والانقطاعات، والطوارئ',
    },
    'section_activities': {
      'tr': 'AKTİVİTELERİM',
      'en': 'MY ACTIVITIES',
      'ar': 'نشاطاتي',
    },
    'act_requests_title': {
      'tr': 'Taleplerim & Başvurularım',
      'en': 'My Requests & Applications',
      'ar': 'طلباتي ومعاملاتي',
    },
    'act_suggestions_title': {
      'tr': 'Söz Sende Önerilerim',
      'en': 'My Suggestions (Your Say)',
      'ar': 'اقتراحاتي (الرأي لك)',
    },
    'act_supports_title': {
      'tr': 'Desteklediklerim & Oylarım',
      'en': 'My Supports & Votes',
      'ar': 'دعوماتي وتصويتاتي',
    },
    'act_saved_title': {
      'tr': 'Kaydettiklerim',
      'en': 'Saved Items',
      'ar': 'العناصر المحفوظة',
    },
    'section_settings': {
      'tr': 'UYGULAMA AYARLARI',
      'en': 'APP SETTINGS',
      'ar': 'إعدادات التطبيق',
    },
    'tile_language': {
      'tr': 'Dil Seçimi',
      'en': 'Language',
      'ar': 'اختيار اللغة',
    },
    'tile_large_font': {
      'tr': 'Büyük Yazı Tipi',
      'en': 'Large Font',
      'ar': 'خط كبير',
    },
    'tile_large_font_sub': {
      'tr': 'Daha rahat okuma için metinleri büyüt',
      'en': 'Enlarge texts for easier reading',
      'ar': 'تكبير النصوص لقراءة أسهل',
    },
    'tile_theme': {
      'tr': 'Tema Tercihi',
      'en': 'Theme Preference',
      'ar': 'تفضيل المظهر',
    },
    'theme_light': {
      'tr': 'Açık Tema',
      'en': 'Light Theme',
      'ar': 'المظهر الفاتح',
    },
    'theme_dark': {
      'tr': 'Koyu Tema',
      'en': 'Dark Theme',
      'ar': 'المظهر الداكن',
    },
    'theme_system': {
      'tr': 'Sistem Varsayılanı',
      'en': 'System Default',
      'ar': 'افتراضي النظام',
    },
    'section_support': {
      'tr': 'DESTEK VE İLETİŞİM',
      'en': 'SUPPORT & CONTACT',
      'ar': 'الدعم والتواصل',
    },
    'tile_gim': {
      'tr': 'Gebze İletişim Merkezi (GİM)',
      'en': 'Gebze Contact Center (GIM)',
      'ar': 'مركز اتصال جبزة',
    },
    'tile_gim_sub': {
      'tr': '444 0 153 • Tek dokunuşla çağrı başlat',
      'en': '444 0 153 • Tap to call',
      'ar': '444 0 153 • اضغط للاتصال',
    },
    'tile_privacy': {
      'tr': 'KVKK ve Gizlilik Politikası',
      'en': 'Privacy Policy & KVKK',
      'ar': 'سياسة الخصوصية وحماية البيانات',
    },
    'tile_privacy_sub': {
      'tr': 'Kişisel verilerinizin korunması hakkında',
      'en': 'About personal data protection',
      'ar': 'حول حماية بياناتك الشخصية',
    },
    'btn_logout': {
      'tr': 'Oturumu Kapat',
      'en': 'Log Out',
      'ar': 'تسجيل الخروج',
    },
    'btn_delete_account': {
      'tr': 'Hesabımı Sil',
      'en': 'Delete My Account',
      'ar': 'حذف حسابي',
    },
    'dialog_edit_profile': {
      'tr': 'Bilgilerimi Düzenle',
      'en': 'Edit My Details',
      'ar': 'تعديل بياناتي',
    },
    'btn_save': {
      'tr': 'Kaydet ve Güncelle',
      'en': 'Save & Update',
      'ar': 'حفظ وتحديث',
    },
    'btn_cancel': {
      'tr': 'İptal',
      'en': 'Cancel',
      'ar': 'إلغاء',
    },
    'btn_confirm_delete': {
      'tr': 'Evet, Hesabımı Sil',
      'en': 'Yes, Delete Account',
      'ar': 'نعم، احذف حسابي',
    },
    'app_footer': {
      'tr': 'Gebze Belediyesi Dijital Vatandaş Platformu v1.0.0',
      'en': 'Gebze Municipality Digital Citizen Platform v1.0.0',
      'ar': 'منصة المواطن الرقمي لبلدية جبزة v1.0.0',
    },
  };

  /// Belirli bir anahtar ve dil için çeviriyi döndürür
  static String get(String key, String lang) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['tr'] ?? key;
  }
}

/// Kolay kullanım için BuildContext extension'ı
extension AppLocalizationsExt on BuildContext {
  String tr(String key, [WidgetRef? ref]) {
    String lang = 'tr';
    if (ref != null) {
      lang = ref.watch(appLanguageProvider);
    }
    return AppStrings.get(key, lang);
  }
}
