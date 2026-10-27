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

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, String>(
  AppLanguageNotifier.new,
);

class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    // ───────────────────────── Alt Menü (Bottom Nav) ─────────────────────────
    'nav_home': {'tr': 'ANA SAYFA', 'en': 'HOME', 'ar': 'الرئيسية'},
    'nav_guide': {'tr': 'REHBER', 'en': 'GUIDE', 'ar': 'دليل'},
    'nav_report': {'tr': 'BİLDİR', 'en': 'REPORT', 'ar': 'إبلاغ'},
    'nav_services': {'tr': 'HİZMETLER', 'en': 'SERVICES', 'ar': 'الخدمات'},
    'nav_profile': {'tr': 'PROFİL', 'en': 'PROFILE', 'ar': 'الملف الشخصي'},

    // ───────────────────────── Genel / Ortak ─────────────────────────
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
    'coming_soon': {'tr': 'yakında', 'en': 'coming soon', 'ar': 'قريباً'},
    'error_occurred': {
      'tr': 'Bir Hata Oluştu',
      'en': 'An Error Occurred',
      'ar': 'حدث خطأ',
    },
    'see_all': {'tr': 'Tümünü Gör', 'en': 'See All', 'ar': 'عرض الكل'},
    'dismiss': {'tr': 'Vazgeç', 'en': 'Dismiss', 'ar': 'تراجع'},
    'btn_cancel': {'tr': 'İptal', 'en': 'Cancel', 'ar': 'إلغاء'},
    'btn_save': {
      'tr': 'Kaydet ve Güncelle',
      'en': 'Save & Update',
      'ar': 'حفظ وتحديث',
    },
    'btn_send': {'tr': 'Gönder', 'en': 'Submit', 'ar': 'إرسال'},
    'btn_retry': {
      'tr': 'Tekrar Dene',
      'en': 'Try Again',
      'ar': 'إعادة المحاولة',
    },
    'btn_back': {'tr': 'Geri', 'en': 'Back', 'ar': 'رجوع'},
    'btn_call': {'tr': 'Ara', 'en': 'Call', 'ar': 'اتصال'},
    'btn_directions': {
      'tr': 'Yol Tarifi',
      'en': 'Directions',
      'ar': 'الاتجاهات',
    },
    'btn_map': {
      'tr': 'Haritada Gör',
      'en': 'View on Map',
      'ar': 'عرض على الخريطة',
    },
    'gebze_city': {'tr': 'Gebze', 'en': 'Gebze', 'ar': 'جبزة'},
    'gebze_municipality': {
      'tr': 'Gebze Belediyesi',
      'en': 'Gebze Municipality',
      'ar': 'بلدية جبزة',
    },
    'mahalle_suffix': {'tr': 'Mahallesi', 'en': 'Neighborhood', 'ar': 'حي'},
    'mahalle_abbr': {'tr': 'Mah.', 'en': 'Dist.', 'ar': 'حي'},
    'filter_all': {'tr': 'Tümü', 'en': 'All', 'ar': 'الكل'},

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
    'qa_places': {
      'tr': 'GEZİLECEK YER',
      'en': 'ATTRACTIONS',
      'ar': 'معالم سياحية',
    },
    'qa_food': {'tr': 'YEME İÇME', 'en': 'FOOD & DRINK', 'ar': 'طعام وشراب'},
    'qa_ebel': {'tr': 'E-BEL', 'en': 'E-MUN', 'ar': 'البلدية'},
    'qa_complaint': {
      'tr': 'MİSAFİR ŞİKAYET',
      'en': 'GUEST REPORT',
      'ar': 'شكاوى الزوار',
    },
    'qa_parking': {'tr': 'OTOPARK', 'en': 'PARKING', 'ar': 'مواقف السيارات'},
    'events_title': {
      'tr': 'YAKLAŞAN ETKİNLİKLER',
      'en': 'UPCOMING EVENTS',
      'ar': 'الفعاليات القادمة',
    },
    'no_events_found': {
      'tr': 'Yaklaşan etkinlik bulunmuyor',
      'en': 'No upcoming events',
      'ar': 'لا توجد فعاليات قادمة',
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
    'current_weather_pill': {
      'tr': 'Güncel Hava Durumu',
      'en': 'Current Weather',
      'ar': 'الطقس الحالي',
    },
    'hp_eskihisar_title': {
      'tr': 'Eskihisar Kalesi',
      'en': 'Eskihisar Castle',
      'ar': 'قلعة إسكي حصار',
    },
    'hp_eskihisar_sub': {
      'tr': 'Tarihi kale ve sahil',
      'en': 'Historic castle and coast',
      'ar': 'قلعة تاريخية وساحل',
    },
    'hp_cmp_title': {
      'tr': 'Çoban Mustafa Paşa Külliyesi',
      'en': 'Coban Mustafa Pasha Complex',
      'ar': 'مجمع جوبان مصطفى باشا',
    },
    'hp_cmp_sub': {
      'tr': 'Osmanlı dönemi külliye',
      'en': 'Ottoman era complex',
      'ar': 'مجمع من العهد العثماني',
    },
    'hp_hannibal_title': {
      'tr': 'Hannibal Anıt Mezarı',
      'en': 'Hannibal Memorial Tomb',
      'ar': 'ضريح حنبعل التذكاري',
    },
    'hp_hannibal_sub': {
      'tr': 'Antik dönem anıtı',
      'en': 'Ancient era monument',
      'ar': 'نصب تذكاري قديم',
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
      'tr': 'Tahmini boş park yerleri',
      'en': 'Estimated empty spots',
      'ar': 'المواقف الشاغرة التقديرية',
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
    'service_weather': {'tr': 'Hava Durumu', 'en': 'Weather', 'ar': 'الطقس'},
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
    'service_assistant': {
      'tr': 'AsistanBot',
      'en': 'AssistantBot',
      'ar': 'المساعد الذكي',
    },
    'service_assistant_sub': {
      'tr': 'Sorularını yapay zekâ ile yanıtla',
      'en': 'Answer your questions with AI',
      'ar': 'أجب على أسئلتك بالذكاء الاصطناعي',
    },
    'service_news': {'tr': 'Haberler', 'en': 'News', 'ar': 'الأخبار'},
    'service_news_sub': {
      'tr': 'Belediyeden güncel haberler',
      'en': 'Latest news from the municipality',
      'ar': 'آخر أخبار البلدية',
    },
    'no_services_found': {
      'tr': 'Aradığınız hizmet bulunamadı',
      'en': 'No services found',
      'ar': 'لم يتم العثور على خدمات',
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
    'weather_not_found': {
      'tr': 'Hava durumu bilgisi bulunamadı.',
      'en': 'Weather data unavailable.',
      'ar': 'بيانات الطقس غير متوفرة.',
    },
    'refresh_weather': {'tr': 'Yenile', 'en': 'Refresh', 'ar': 'تحديث'},
    'refreshing_weather': {
      'tr': 'Hava durumu güncelleniyor...',
      'en': 'Updating weather...',
      'ar': 'جاري تحديث الطقس...',
    },
    'feels_like': {'tr': 'Hissedilen', 'en': 'Feels like', 'ar': 'المحسوس'},
    'humidity': {'tr': 'Nem', 'en': 'Humidity', 'ar': 'الرطوبة'},
    'wind': {'tr': 'Rüzgar', 'en': 'Wind', 'ar': 'الرياح'},
    'hourly_forecast': {
      'tr': 'Günün Saatlik Tahmini',
      'en': 'Today\'s Hourly Forecast',
      'ar': 'التوقعات بالساعة لليوم',
    },
    'five_day_forecast': {
      'tr': '5 Günlük Hava Tahmini',
      'en': '5-Day Weather Forecast',
      'ar': 'توقعات الطقس لخمسة أيام',
    },
    'forecast_days_badge': {
      'tr': '{0} Günlük',
      'en': '{0} Days',
      'ar': '{0} أيام',
    },
    'now': {'tr': 'Şimdi', 'en': 'Now', 'ar': 'الآن'},
    'today': {'tr': 'Bugün', 'en': 'Today', 'ar': 'اليوم'},
    'tomorrow': {'tr': 'Yarın', 'en': 'Tomorrow', 'ar': 'غداً'},
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
      'tr': 'Son Güncelleme',
      'en': 'Last Updated',
      'ar': 'آخر تحديث',
    },

    // ───────────────────────── Acil Durum & Toplanma ─────────────────────────
    'emergency_screen_title': {
      'tr': 'ACİL DURUM & TOPLANMA',
      'en': 'EMERGENCY & ASSEMBLY',
      'ar': 'الطوارئ ونقاط التجمع',
    },
    'emergency_screen_sub': {
      'tr': 'Gebze acil çağrı hatları ve en yakın güvenli toplanma bölgeleri.',
      'en': 'Gebze emergency hotlines and nearest assembly zones.',
      'ar': 'خطوط طوارئ جبزة وأقرب مناطق التجمع الآمنة.',
    },
    'call_center_112_title': {
      'tr': '112 ACİL ÇAĞRI MERKEZİ',
      'en': '112 EMERGENCY CALL CENTER',
      'ar': '112 مركز الاتصال للطوارئ',
    },
    'call_center_112_sub': {
      'tr': 'Ambulans, İtfaiye, Polis, Jandarma, AFAD',
      'en': 'Ambulance, Fire, Police, Gendarmerie, AFAD',
      'ar': 'إسعاف، إطفاء، شرطة، درك، إدارة الكوارث',
    },
    'quick_call_label': {
      'tr': 'HIZLI ARAMA NUMARALARI',
      'en': 'QUICK DIAL NUMBERS',
      'ar': 'أرقام الاتصال السريع',
    },
    'gebze_bld_label': {
      'tr': 'Gebze Belediyesi',
      'en': 'Gebze Municipality',
      'ar': 'بلدية جبزة',
    },
    'white_desk_sub': {
      'tr': 'Beyaz Masa Çağrı',
      'en': 'White Desk Hotline',
      'ar': 'الخط الساخن للبلدية',
    },
    'afad_label': {'tr': 'AFAD', 'en': 'AFAD', 'ar': 'إدارة الكوارث'},
    'afad_sub': {
      'tr': 'Afet ve Acil Durum',
      'en': 'Disaster and Emergency',
      'ar': 'الكوارث والطوارئ',
    },
    'utility_emergency_label': {
      'tr': 'ARIZA & İHBAR HATLARI',
      'en': 'UTILITY & REPORT LINES',
      'ar': 'خطوط الأعطال والبلاغات',
    },
    'sedas_sub': {
      'tr': 'Elektrik Arıza (186)',
      'en': 'Power Outage (186)',
      'ar': 'طوارئ الكهرباء (186)',
    },
    'isu_sub': {
      'tr': 'Su & Kanal Arıza (185)',
      'en': 'Water & Sewer Outage (185)',
      'ar': 'طوارئ المياه والصرف (185)',
    },
    'palgaz_sub': {
      'tr': 'Doğalgaz Acil (187)',
      'en': 'Natural Gas Emergency (187)',
      'ar': 'طوارئ الغاز الطبيعي (187)',
    },
    'zabita_sub': {
      'tr': 'Zabıta & İhbar (153)',
      'en': 'Municipal Police (153)',
      'ar': 'شرطة البلدية (153)',
    },
    'assembly_areas_label': {
      'tr': 'ACİL TOPLANMA ALANLARI',
      'en': 'EMERGENCY ASSEMBLY AREAS',
      'ar': 'مناطق التجمع في حالات الطوارئ',
    },
    'areas_count_badge': {
      'tr': '{0} Alan',
      'en': '{0} Areas',
      'ar': '{0} منطقة',
    },
    'search_assembly_hint': {
      'tr': 'Mahalle veya toplanma alanı ara...',
      'en': 'Search neighborhood or assembly area...',
      'ar': 'ابحث عن حي أو منطقة تجمع...',
    },
    'no_assembly_found': {
      'tr': 'Aradığınız kritere uygun toplanma alanı bulunamadı.',
      'en': 'No assembly areas found matching criteria.',
      'ar': 'لم يتم العثور على منطقة تجمع مطابقة.',
    },
    'calling_toast': {
      'tr': '{0} ({1}) aranıyor...',
      'en': 'Calling {0} ({1})...',
      'ar': 'جاري الاتصال بـ {0} ({1})...',
    },
    'route_toast': {
      'tr': '{0} için haritada rota başlatılıyor...',
      'en': 'Starting route on map for {0}...',
      'ar': 'جاري بدء المسار على الخريطة لـ {0}...',
    },

    // ───────────────────────── Planlı Kesintiler ─────────────────────────
    'outages_screen_title': {
      'tr': 'PLANLI KESİNTİLER',
      'en': 'PLANNED OUTAGES',
      'ar': 'الانقطاعات المجدولة',
    },
    'outages_screen_sub': {
      'tr':
          'Gebze geneli su, elektrik ve doğalgaz şebeke kesinti bildirimleri.',
      'en': 'Water, electricity and gas network outage alerts in Gebze.',
      'ar': 'إشعارات انقطاع شبكات المياه والكهرباء والغاز في جبزة.',
    },
    'filter_water': {
      'tr': 'Su (İSU)',
      'en': 'Water (ISU)',
      'ar': 'المياه (ISU)',
    },
    'filter_electric': {
      'tr': 'Elektrik (SEDAŞ)',
      'en': 'Electricity (SEDAS)',
      'ar': 'الكهرباء (SEDAS)',
    },
    'filter_gas': {
      'tr': 'Doğalgaz (PALGAZ)',
      'en': 'Gas (PALGAZ)',
      'ar': 'الغاز (PALGAZ)',
    },
    'status_ongoing': {
      'tr': 'Devam Ediyor',
      'en': 'In Progress',
      'ar': 'قيد التنفيذ',
    },
    'status_planned': {
      'tr': 'Planlı Kesinti',
      'en': 'Planned Outage',
      'ar': 'انقطاع مجدول',
    },
    'status_completed': {'tr': 'Tamamlandı', 'en': 'Completed', 'ar': 'مكتمل'},
    'outage_start': {'tr': 'Başlangıç', 'en': 'Start', 'ar': 'البداية'},
    'outage_end': {'tr': 'Bitiş', 'en': 'End', 'ar': 'النهاية'},
    'no_outages_found': {
      'tr': 'Seçilen kategoride aktif veya planlı bir kesinti bulunmuyor.',
      'en': 'No active or planned outages in this category.',
      'ar': 'لا توجد انقطاعات نشطة أو مجدولة في هذه الفئة.',
    },

    // ───────────────────────── Şehir Rehberi ─────────────────────────
    'guide_screen_title': {
      'tr': 'Şehir Rehberi',
      'en': 'City Guide',
      'ar': 'دليل المدينة',
    },
    'tab_institutions': {
      'tr': 'Kurumsal Hizmetler',
      'en': 'Municipal Services',
      'ar': 'الخدمات المؤسسية',
    },
    'tab_discover': {
      'tr': "Gebze'yi Keşfet",
      'en': 'Discover Gebze',
      'ar': 'اكتشف جبزة',
    },
    'search_institution_hint': {
      'tr': 'Hizmet veya birim ara...',
      'en': 'Search service or department...',
      'ar': 'بحث عن خدمة أو إدارة...',
    },
    'search_places_hint': {
      'tr': 'Mekan, müze veya park ara...',
      'en': 'Search places, museums or parks...',
      'ar': 'بحث عن مكان أو متحف أو حديقة...',
    },
    'no_institution_found': {
      'tr': 'Aradığınız birim bulunamadı',
      'en': 'Department not found',
      'ar': 'لم يتم العثور على الإدارة',
    },
    'no_places_found': {
      'tr': 'Aradığınız mekan bulunamadı',
      'en': 'Place not found',
      'ar': 'لم يتم العثور على المكان',
    },
    'no_category_records': {
      'tr': 'Bu kategori için henüz kayıt eklenmedi.',
      'en': 'No records for this category yet.',
      'ar': 'لا توجد سجلات لهذه الفئة بعد.',
    },
    'cat_parks': {
      'tr': 'Parklar ve Kütüphaneler',
      'en': 'Parks and Libraries',
      'ar': 'الحدائق والمكتبات',
    },
    'cat_restaurants': {
      'tr': 'Kent Lokantaları',
      'en': 'City Restaurants',
      'ar': 'مطاعم المدينة',
    },
    'cat_markets': {
      'tr': 'Pazar Yerleri',
      'en': 'Market Places',
      'ar': 'الأسواق',
    },
    'cat_sports': {
      'tr': 'Spor Tesisleri',
      'en': 'Sports Facilities',
      'ar': 'المنشآت الرياضية',
    },
    'cat_culture': {
      'tr': 'Kültür Merkezleri',
      'en': 'Cultural Centers',
      'ar': 'المراكز الثقافية',
    },
    'cat_cemeteries': {
      'tr': 'Mezarlıklar',
      'en': 'Cemeteries',
      'ar': 'المقابر',
    },
    'cat_municipality': {
      'tr': 'Belediye Tesisleri',
      'en': 'Municipal Facilities',
      'ar': 'المنشآت البلدية',
    },
    'cat_events': {
      'tr': 'Yaklaşan Etkinlikler',
      'en': 'Upcoming Events',
      'ar': 'الفعاليات القادمة',
    },
    'filter_historic': {'tr': 'Tarihi', 'en': 'Historic', 'ar': 'تاريخي'},
    'filter_museums': {'tr': 'Müzeler', 'en': 'Museums', 'ar': 'متاحف'},
    'filter_nature': {'tr': 'Doğa', 'en': 'Nature', 'ar': 'طبيعة'},
    'filter_mosques': {'tr': 'Camiler', 'en': 'Mosques', 'ar': 'مساجد'},
    'page_open_error': {
      'tr': 'Sayfa açılamadı. Lütfen tekrar deneyin.',
      'en': 'Page could not be opened. Please try again.',
      'ar': 'تعذر فتح الصفحة. يرجى المحاولة مرة أخرى.',
    },

    // ───────────────────────── Nöbetçi Eczaneler ─────────────────────────
    'pharmacy_screen_title': {
      'tr': 'NÖBETÇİ ECZANELER',
      'en': 'PHARMACIES ON DUTY',
      'ar': 'الصيدليات المناوبة',
    },
    'pharmacy_screen_sub': {
      'tr': 'Gebze genelinde nöbetçi eczane bilgileri ve iletişim.',
      'en': 'Pharmacies on duty information and contact in Gebze.',
      'ar': 'معلومات الصيدليات المناوبة والاتصال في جبزة.',
    },
    'no_pharmacy_found': {
      'tr': 'Bugün için nöbetçi eczane bulunamadı.',
      'en': 'No pharmacies on duty found for today.',
      'ar': 'لم يتم العثور على صيدليات مناوبة اليوم.',
    },

    // ───────────────────────── Söz Sende ─────────────────────────
    'soz_sende_title': {'tr': 'SÖZ SENDE', 'en': 'YOUR SAY', 'ar': 'الرأي لك'},
    'soz_sende_subtitle': {
      'tr': 'Gebze için fikirlerini paylaş, oylamalara katıl ve şehrini birlikte yönet.',
      'en': 'Share ideas for Gebze, join votes, and co-govern your city.',
      'ar': 'شارك أفكارك لجبزة، وشارك بالتصويت، وأدر مدينتك معاً.',
    },
    'tab_polls': {
      'tr': 'Aktif Anketler',
      'en': 'Active Polls',
      'ar': 'استطلاعات نشطة',
    },
    'tab_suggestions': {
      'tr': 'Vatandaş Önerileri',
      'en': 'Citizen Suggestions',
      'ar': 'مقترحات المواطنين',
    },
    'poll_deadline': {
      'tr': 'Son Tarih:',
      'en': 'Deadline:',
      'ar': 'تاريخ الانتهاء:',
    },
    'poll_total_votes': {
      'tr': 'Toplam Oy',
      'en': 'Total Votes',
      'ar': 'إجمالي الأصوات',
    },
    'poll_btn_vote': {'tr': 'Oy Ver', 'en': 'Vote', 'ar': 'تصويت'},
    'poll_btn_voted': {
      'tr': 'Oyunuz Kaydedildi',
      'en': 'Voted',
      'ar': 'تم تسجيل صوتك',
    },
    'btn_support': {'tr': 'Destekle', 'en': 'Support', 'ar': 'دعم'},
    'btn_supported': {
      'tr': 'Desteklediniz',
      'en': 'Supported',
      'ar': 'تم الدعم',
    },
    'status_reviewing': {
      'tr': 'İnceleniyor',
      'en': 'Under Review',
      'ar': 'قيد المراجعة',
    },
    'status_pending': {
      'tr': 'Beklemede',
      'en': 'Pending',
      'ar': 'قيد الانتظار',
    },
    'status_approved': {
      'tr': 'Onaylandı',
      'en': 'Approved',
      'ar': 'تمت الموافقة',
    },
    'status_under_review': {
      'tr': 'İnceleme Aşamasında',
      'en': 'Under Review',
      'ar': 'قيد المراجعة',
    },
    'status_under_review_desc': {
      'tr': 'Bu öneriniz inceleme aşamasındadır. Yönetici onayından sonra tüm vatandaşların oylamasına açılacaktır.',
      'en': 'This proposal is under review. It will open for voting after admin approval.',
      'ar': 'هذا المقترح قيد المراجعة. سيتم فتح التصويت بعد موافقة الإدارة.',
    },
    'status_only_you_see': {
      'tr': 'Yalnızca Siz Görüyorsunuz',
      'en': 'Only Visible to You',
      'ar': 'مرئي لك فقط',
    },
    'status_voting_disabled_pending': {
      'tr': 'Onaylandıktan sonra oylamaya açılacaktır',
      'en': 'Voting opens after approval',
      'ar': 'سيتم فتح التصويت بعد الموافقة',
    },
    'status_published': {
      'tr': 'Yayında',
      'en': 'Published',
      'ar': 'منشور',
    },
    'no_suggestions_found': {
      'tr': 'Henüz onaylanmış bir öneri bulunmuyor.',
      'en': 'No approved suggestions found.',
      'ar': 'لا توجد مقترحات معتمدة بعد.',
    },
    'btn_new_suggestion': {
      'tr': 'Yeni Öneri Paylaş',
      'en': 'Share New Idea',
      'ar': 'شارك فكرة جديدة',
    },
    'dialog_new_suggestion_title': {
      'tr': 'Fikir / Öneri Paylaş',
      'en': 'Share Idea / Proposal',
      'ar': 'شارك فكرة / مقترح',
    },
    'input_suggestion_title': {
      'tr': 'Öneri Başlığı',
      'en': 'Proposal Title',
      'ar': 'عنوان المقترح',
    },
    'input_suggestion_desc': {
      'tr': 'Açıklama',
      'en': 'Description',
      'ar': 'الوصف',
    },
    'input_neighborhood': {'tr': 'Mahalle', 'en': 'Neighborhood', 'ar': 'الحي'},
    'input_category': {'tr': 'Kategori', 'en': 'Category', 'ar': 'الفئة'},
    'suggestion_sent_toast': {
      'tr': 'Öneriniz incelenmek üzere başarıyla gönderildi.',
      'en': 'Your proposal was submitted for review.',
      'ar': 'تم إرسال مقترحك للمراجعة بنجاح.',
    },
    'fill_fields_warning': {
      'tr': 'Lütfen başlık ve açıklama alanlarını doldurun.',
      'en': 'Please fill in title and description fields.',
      'ar': 'يرجى ملء حقول العنوان والوصف.',
    },
    'cat_transport': {
      'tr': 'Ulaşım',
      'en': 'Transportation',
      'ar': 'المواصلات',
    },
    'cat_environment': {'tr': 'Çevre', 'en': 'Environment', 'ar': 'البيئة'},
    'cat_parks_gardens': {
      'tr': 'Park & Bahçe',
      'en': 'Parks & Gardens',
      'ar': 'الحدائق والمتنزهات',
    },
    'cat_infrastructure': {
      'tr': 'Altyapı',
      'en': 'Infrastructure',
      'ar': 'البنية التحتية',
    },
    'cat_social_service': {
      'tr': 'Sosyal Hizmet',
      'en': 'Social Service',
      'ar': 'الخدمات الاجتماعية',
    },
    'cat_other': {'tr': 'Diğer', 'en': 'Other', 'ar': 'أخرى'},

    // ───────────────────────── Gebze Pati ─────────────────────────
    'pati_screen_title': {
      'tr': 'GEBZE PATİ',
      'en': 'GEBZE PAWS',
      'ar': 'رعاية الحيوانات',
    },
    'pati_screen_sub': {
      'tr': 'Sokak Hayvanları ve Can Dostlarımız',
      'en': 'Street Animals & Animal Friends',
      'ar': 'حيوانات الشارع وأصدقاؤنا الأوفياء',
    },
    'tab_ambulance': {
      'tr': 'Ambulans & Merkez',
      'en': 'Ambulance & Center',
      'ar': 'الإسعاف والمركز',
    },
    'tab_adoption': {'tr': 'Sahiplendirme', 'en': 'Adoption', 'ar': 'التبني'},
    'tab_food_clinics': {
      'tr': 'Mama & Klinikler',
      'en': 'Food & Clinics',
      'ar': 'الطعام والعيادات',
    },
    'ambulance_banner_title': {
      'tr': 'Hayvan Ambulansı',
      'en': 'Animal Ambulance',
      'ar': 'إسعاف الحيوانات',
    },
    'ambulance_banner_team': {
      'tr': 'Gebze Belediyesi Veteriner Hizmetleri',
      'en': 'Gebze Municipality Veterinary Services',
      'ar': 'خدمات الطب البيطري لبلدية جبزة',
    },
    'ambulance_banner_desc': {
      'tr': 'Yardıma muhtaç ve yaralı sokak hayvanlarımız için Gebze Belediyesi Hayvan Ambulansı hizmetinizdedir.',
      'en': 'Gebze Municipality Animal Ambulance is at your service for street animals in need.',
      'ar': 'إسعاف بلدية جبزة للحيوانات في خدمتكم لحيوانات الشارع المحتاجة للمساعدة.',
    },
    'call_ambulance_btn': {
      'tr': 'Hayvan Ambulansını Ara (0262 642 04 30)',
      'en': 'Call Animal Ambulance (0262 642 04 30)',
      'ar': 'اتصل بإسعاف الحيوانات (0262 642 04 30)',
    },
    'ambulance_what_is_title': {
      'tr': 'Hayvan Ambulansı Nedir?',
      'en': 'What is the Pet Ambulance?',
      'ar': 'ما هي سيارة إسعاف الحيوانات؟',
    },
    'ambulance_what_is_desc': {
      'tr': 'Trafik kazası, yüksekten düşme, zehirlenme ve akut yaralanmalarda olay yerine hızla intikal eden, tam donanımlı ilk müdahale acil aracıdır.',
      'en': 'A fully equipped emergency vehicle dispatched rapidly to scenes of traffic accidents, falls, poisonings, and acute injuries.',
      'ar': 'مركبة طوارئ مجهزة بالكامل للوصول السريع إلى حوادث السير، السقوط، التسمم والإصابات الحادة.',
    },
    'ambulance_interventions_title': {
      'tr': 'Acil Müdahale Kapsamı',
      'en': 'Emergency Scope',
      'ar': 'نطاق التدخل في حالات الطوارئ',
    },
    'rehab_center_section_title': {
      'tr': 'Sokak Hayvanları Rehabilitasyon ve Eğitim Merkezi',
      'en': 'Street Animals Rehabilitation & Training Center',
      'ar': 'مركز إعادة تأهيل وتدريب حيوانات الشارع',
    },
    'rehab_center_section_sub': {
      'tr': 'Tedavi, bakım, aşılama ve sahiplendirme yerleşkesi',
      'en': 'Treatment, care, vaccination and adoption campus',
      'ar': 'مجمع العلاج والرعاية والتطعيم والتبني',
    },
    'center_call_btn': {
      'tr': 'Merkezi Ara',
      'en': 'Call Center',
      'ar': 'اتصل بالمركز',
    },
    'center_directions_btn': {
      'tr': 'Merkeze Yol Tarifi',
      'en': 'Directions to Center',
      'ar': 'الاتجاهات إلى المركز',
    },
    'adoption_header_title': {
      'tr': 'Yuva Arayan Can Dostlarımız',
      'en': 'Looking for a Loving Home',
      'ar': 'يبحثون عن مأوى دافئ',
    },
    'adoption_header_sub': {
      'tr': 'Bir cana sıcacık bir yuva olun, satın almayın sahiplenin!',
      'en': 'Give a warm home, dont buy, adopt!',
      'ar': 'امنحهم مأوى دافئاً، لا تشترِ بل تبنَّ!',
    },
    'btn_call_for_adoption': {
      'tr': 'Sahiplenmek İçin Ara',
      'en': 'Call to Adopt',
      'ar': 'اتصل للتبني',
    },
    'no_pets_found': {
      'tr': 'Şu an sahiplendirilmeyi bekleyen can dostumuz bulunmuyor.',
      'en': 'No pets currently waiting for adoption.',
      'ar': 'لا توجد حيوانات تنتظر التبني حالياً.',
    },
    'feeding_points_title': {
      'tr': 'Mama ve Su Odakları Ağı',
      'en': 'Food & Water Feeding Points Network',
      'ar': 'شبكة نقاط توزيع الطعام والماء',
    },
    'feeding_points_sub': {
      'tr': 'Gebze genelinde can dostlarımız için kurulan düzenli besleme istasyonları.',
      'en': 'Regular feeding stations established for animal friends across Gebze.',
      'ar': 'محطات تغذية منتظمة أقيمت لأصدقائنا الحيوانات في جميع أنحاء جبزة.',
    },
    'no_feeding_points_in_neighborhood': {
      'tr': 'Bu mahallede kayıtlı besleme odağı bulunamadı.',
      'en': 'No feeding points registered in this neighborhood.',
      'ar': 'لم يتم العثور على محطات تغذية مسجلة في هذا الحي.',
    },
    'vet_clinics_title': {
      'tr': 'Özel Nöbetçi Veteriner Klinikleri',
      'en': 'Emergency Veterinary Clinics',
      'ar': 'عيادات بيطرية خاصة مناوبة',
    },
    'vet_clinics_sub': {
      'tr': 'Acil müdahale ve tedavi için anlaşmalı ve nöbetçi veteriner klinikleri.',
      'en': 'Contracted and on-duty veterinary clinics for emergency intervention and care.',
      'ar': 'عيادات بيطرية مناوبة ومتعاقدة للتدخل العاجل والرعاية.',
    },

    // ───────────────────────── E-Belediye ─────────────────────────
    'ebelediye_screen_title': {
      'tr': 'E-BELEDİYE',
      'en': 'E-MUNICIPALITY',
      'ar': 'البلدية الإلكترونية',
    },
    'ebelediye_screen_sub': {
      'tr': 'Gebze Belediyesi resmi online işlemleri ve bilgi rehberi.',
      'en': 'Gebze Municipality official online services and info guide.',
      'ar': 'الخدمات الإلكترونية الرسمية لبلدية جبزة ودليل المعلومات.',
    },
    'search_ebelediye_hint': {
      'tr': 'Vergi, beyan, ruhsat veya işlem ara...',
      'en': 'Search tax, declaration, license or service...',
      'ar': 'ابحث عن ضريبة أو إقرار أو رخصة أو خدمة...',
    },
    'official_portal_sub': {
      'tr': 'Gebze Belediyesi Resmi Portalı',
      'en': 'Gebze Municipality Official Portal',
      'ar': 'بوابة بلدية جبزة الرسمية',
    },
    'id_verify_info': {
      'tr': 'Kimlik Doğrulama Bilgisi',
      'en': 'Identity Verification Info',
      'ar': 'معلومات التحقق من الهوية',
    },
    'security_note': {
      'tr': '📌 Not: Güvenliğiniz ve vergi/başvuru gizliliği nedeniyle işlem Gebze Belediyesi resmi sayfasında e-Devlet veya T.C. Kimlik doğrulaması ile devam edecektir.',
      'en': '📌 Note: For security and confidentiality, the transaction will continue on the official Gebze Municipality portal with e-Devlet authentication.',
      'ar': '📌 ملاحظة: لأمانك وسرية طلباتك، ستستمر المعاملة على بوابة بلدية جبزة الرسمية عبر بوابة e-Devlet.',
    },
    'btn_start_service': {
      'tr': 'İşleme Başla',
      'en': 'Start Action',
      'ar': 'بدء المعاملة',
    },
    'wizard_title': {
      'tr': 'Lütfen İşlem Tipini Seçin',
      'en': 'Please Select Action Type',
      'ar': 'يرجى اختيار نوع المعاملة',
    },
    'wizard_sub': {
      'tr': 'Yapmak istediğiniz işlem adımını belirleyiniz',
      'en': 'Determine the step of the operation you want to perform',
      'ar': 'حدد خطوة المعاملة التي ترغب بإجرائها',
    },

    // ───────────────────────── Haberler ─────────────────────────
    'municipal_news_title': {
      'tr': 'BELEDİYE HABERLERİ',
      'en': 'MUNICIPAL NEWS',
      'ar': 'أخبار البلدية',
    },
    'municipal_news_sub': {
      'tr': 'Gebze Belediyesi ile ilgili en güncel haberler ve duyurular.',
      'en': 'Latest news and announcements regarding Gebze Municipality.',
      'ar': 'آخر الأخبار والإعلانات المتعلقة ببلدية جبزة.',
    },
    'news_badge_title': {
      'tr': 'GEBZE BELEDİYESİ GÜNCEL',
      'en': 'GEBZE MUNICIPALITY NEWS',
      'ar': 'أخبار بلدية غبزة',
    },
    'news_preview_title': {
      'tr': 'Haber Önizlemesi',
      'en': 'News Preview',
      'ar': 'معاينة الخبر',
    },
    'news_empty_text': {
      'tr': 'Henüz haber bulunmuyor.',
      'en': 'No news available yet.',
      'ar': 'لا توجد أخبار حالياً.',
    },
    'news_load_failed': {
      'tr': 'Haberler yüklenemedi.',
      'en': 'Failed to load news.',
      'ar': 'تعذر تحميل الأخبار.',
    },
    'news_read_more_info': {
      'tr': 'Bu haberin tamamını okumak ve daha fazla detaya ulaşmak için lütfen aşağıdaki butona tıklayarak orijinal kaynağa (Gebze Belediyesi web sitesine) gidin.',
      'en': 'To read the full news and access more details, please click the button below to visit the official source (Gebze Municipality website).',
      'ar': 'لقراءة الخبر كاملاً والاطلاع على مزيد من التفاصيل، يرجى النقر على الزر أدناه للانتقال للمصدر الرسمي (موقع بلدية جبزة).',
    },
    'news_open_browser_btn': {
      'tr': 'Haberi Tarayıcıda Aç',
      'en': 'Open News in Browser',
      'ar': 'فتح الخبر في المتصفح',
    },
    'news_read_more': {
      'tr': 'Devamını Oku',
      'en': 'Read More',
      'ar': 'اقرأ المزيد',
    },
    'news_summary_title': {
      'tr': 'Haber Özeti & Ön Okuma',
      'en': 'News Summary & Preview',
      'ar': 'ملخص الخبر والمعاينة',
    },

    // ───────────────────────── Profil ─────────────────────────
    'profile_screen_title': {
      'tr': 'PROFİLİM',
      'en': 'MY PROFILE',
      'ar': 'ملفي الشخصي',
    },
    'hello': {'tr': 'Merhaba,', 'en': 'Hello,', 'ar': 'مرحباً،'},
    'verified_badge': {
      'tr': 'Doğrulanmış',
      'en': 'Verified',
      'ar': 'تم التحقق',
    },
    'stat_requests': {'tr': 'Taleplerim', 'en': 'My Requests', 'ar': 'طلباتي'},
    'stat_suggestions': {
      'tr': 'Önerilerim',
      'en': 'My Suggestions',
      'ar': 'اقتراحاتي',
    },
    'stat_supports': {'tr': 'Desteklerim', 'en': 'My Supports', 'ar': 'دعمي'},
    'stat_saved': {'tr': 'Kayıtlarım', 'en': 'Saved', 'ar': 'محفوظاتي'},
    'section_account': {
      'tr': 'HESAP BİLGİLERİ',
      'en': 'ACCOUNT INFO',
      'ar': 'معلومات الحساب',
    },
    'tile_my_info': {'tr': 'Bilgilerim', 'en': 'My Details', 'ar': 'معلوماتي'},
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
    'field_full_name': {
      'tr': 'Ad Soyad',
      'en': 'Full Name',
      'ar': 'الاسم الكامل',
    },
    'field_email': {'tr': 'E-posta', 'en': 'Email', 'ar': 'البريد الإلكتروني'},
    'field_phone': {
      'tr': 'Telefon Numarası',
      'en': 'Phone Number',
      'ar': 'رقم الهاتف',
    },
    'field_tc': {
      'tr': 'T.C. Kimlik No',
      'en': 'National ID No',
      'ar': 'الرقم الوطني',
    },
    'field_address': {
      'tr': 'Açık Adres',
      'en': 'Street Address',
      'ar': 'العنوان التفصيلي',
    },
    'profile_updated_toast': {
      'tr': 'Profil bilgileriniz güncellendi.',
      'en': 'Profile information updated.',
      'ar': 'تم تحديث معلومات الملف الشخصي.',
    },
    'dialog_select_neighborhood': {
      'tr': 'Mahallenizi Seçin',
      'en': 'Select Your Neighborhood',
      'ar': 'اختر حيك',
    },
    'select_neighborhood_sub': {
      'tr': 'Mahallenize özel duyuru ve kesinti bildirimleri için mahallenizi kaydedin.',
      'en': 'Save your neighborhood for specific announcements and outage alerts.',
      'ar': 'احفظ حيك لتلقي الإعلانات وتنبيهات الانقطاع الخاصة بحيك.',
    },
    'neighborhood_updated_toast': {
      'tr': 'Mahalleniz güncellendi.',
      'en': 'Neighborhood updated.',
      'ar': 'تم تحديث الحي.',
    },
    'notif_push': {
      'tr': 'Anlık Bildirimler (Push)',
      'en': 'Push Notifications',
      'ar': 'الإشعارات الفورية (Push)',
    },
    'notif_sms': {
      'tr': 'SMS Bildirimleri',
      'en': 'SMS Notifications',
      'ar': 'إشعارات الرسائل القصيرة',
    },
    'notif_outages': {
      'tr': 'Kesinti Uyarıları (Su, Elektrik, Gaz)',
      'en': 'Outage Alerts (Water, Power, Gas)',
      'ar': 'تنبيهات الانقطاع (مياه، كهرباء، غاز)',
    },
    'notif_emergency': {
      'tr': 'Acil Durum & Afet Bildirimleri',
      'en': 'Emergency & Disaster Alerts',
      'ar': 'تنبيهات الطوارئ والكوارث',
    },
    'notif_soz_sende': {
      'tr': 'Söz Sende & Anket Bildirimleri',
      'en': 'Your Say & Poll Alerts',
      'ar': 'تنبيهات الرأي لك والاستطلاعات',
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
    'btn_confirm_delete': {
      'tr': 'Evet, Hesabımı Sil',
      'en': 'Yes, Delete Account',
      'ar': 'نعم، احذف حسابي',
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
    'app_footer': {
      'tr': 'Gebze Belediyesi Dijital Vatandaş Platformu v1.0.0',
      'en': 'Gebze Municipality Digital Citizen Platform v1.0.0',
      'ar': 'منصة المواطن الرقمي لبلدية جبزة v1.0.0',
    },

    // ───────────────────────── İlave Pati & Ambulans ─────────────────────────
    'ambulance_what_is': {
      'tr': 'Hayvan Ambulansı Ne İşe Yarar?',
      'en': 'What Does Pet Ambulance Do?',
      'ar': 'ما هي مهام إسعاف الحيوانات؟',
    },
    'ambulance_what_is_desc_full': {
      'tr': 'Gebze Belediyesi Hayvan Ambulansı; sokakta yaşayan sahipsiz can dostlarımızın trafik kazaları, yüksekten düşme, zehirlenme ve ağır travma gibi acil hayati tehlike içeren durumlarında olay yerinde ilk müdahalenin yapılması ve donanımlı rehabilitasyon merkezine güvenle nakledilmesi için özel olarak tasarlanmış tam teşekküllü acil müdahale aracıdır.',
      'en': 'Gebze Municipality Animal Ambulance is a fully equipped emergency response vehicle specially designed to provide on-site first aid and safe transfer to the rehabilitation center for street animals in life-threatening conditions such as traffic accidents, falls, poisonings, and severe traumas.',
      'ar': 'إسعاف بلدية جبزة للحيوانات هو مركبة طوارئ مجهزة بالكامل صممت خصيصاً لتقديم الإسعافات الأولية ونقل حيوانات الشارع التي تواجه حالات خطرة مثل حوادث السير والسقوط والتسمم إلى مركز التأهيل بأمان.',
    },
    'conditions_title': {
      'tr': 'Hangi Durumlarda Çağırabilirsiniz?',
      'en': 'When Can You Call?',
      'ar': 'في أي الحالات يمكنك الاتصال؟',
    },
    'cond_accident': {
      'tr': 'Trafik Kazası',
      'en': 'Traffic Accident',
      'ar': 'حادث سير',
    },
    'cond_accident_sub': {
      'tr': 'Kırık, kanama veya şok geçiren sokak canlıları',
      'en': 'Animals with fractures, bleeding, or shock',
      'ar': 'حيوانات مصابة بكسور أو نزيف أو صدمة',
    },
    'cond_trauma': {
      'tr': 'Ağır Travma & Düşme',
      'en': 'Severe Trauma & Fall',
      'ar': 'صدمة شديدة وسقوط',
    },
    'cond_trauma_sub': {
      'tr': 'Yüksekten düşme, ezilme veya hareket edememe',
      'en': 'Falls from height, crushing, or inability to move',
      'ar': 'سقوط من ارتفاع أو دهس أو عدم قدرة على الحركة',
    },
    'cond_poison': {
      'tr': 'Zehirlenme Şüphesi',
      'en': 'Suspected Poisoning',
      'ar': 'اشتباه تسمم',
    },
    'cond_poison_sub': {
      'tr': 'Aşırı salya, nöbet geçirme veya solunum güçlüğü',
      'en': 'Excessive drooling, seizures, or respiratory distress',
      'ar': 'لعاب مفرط أو نوبات أو صعوبة في التنفس',
    },
    'cond_wound': {
      'tr': 'Açık Yara & Enfeksiyon',
      'en': 'Open Wound & Infection',
      'ar': 'جروح مفتوحة والتهابات',
    },
    'cond_wound_sub': {
      'tr': 'Hayati tehlike oluşturan derin yara ve uzuv kayıpları',
      'en': 'Life-threatening deep wounds and limb loss',
      'ar': 'جروح عميقة مهددة للحياة وفقدان أطراف',
    },
    'ambulance_interventions_label': {
      'tr': 'Ambulans Ekiplerince Yapılan Müdahaleler:',
      'en': 'Interventions by Ambulance Teams:',
      'ar': 'التدخلات التي تقوم بها فرق الإسعاف:',
    },
    'proc_1': {
      'tr': 'Olay yerinde uzman veteriner hekim / tekniker kontrolü',
      'en': 'On-site specialist veterinarian / technician inspection',
      'ar': 'فحص في الموقع بواسطة طبيب بيطري أو فني مختص',
    },
    'proc_2': {
      'tr': 'Acil kanama durdurma, oksijen desteği ve serum takviyesi',
      'en': 'Emergency bleeding control, oxygen support, and IV fluids',
      'ar': 'وقف النزيف الطارئ ودعم الأكسجين والمحاليل',
    },
    'proc_3': {
      'tr': 'Kırık ve travma stabilizasyonu ile sedye ile güvenli nakil',
      'en': 'Fracture & trauma stabilization with safe stretcher transport',
      'ar': 'تثبيت الكسور والصدمات ونقل آمن بالحمالة',
    },
    'proc_4': {
      'tr': 'Pelitli Rehabilitasyon Merkezi yoğun bakım ve ameliyathaneye hızlı sevk',
      'en': 'Rapid dispatch to Pelitli Rehabilitation Center ICU and surgery',
      'ar': 'إحالة سريعة إلى العناية المركزة وغرفة العمليات بمركز بيليتلي',
    },
    'google_reviews_count': {
      'tr': '(149 Google Yorumu)',
      'en': '(149 Google Reviews)',
      'ar': '(149 تقييم على Google)',
    },
    'pelitli_hospital': {
      'tr': 'Pelitli Hayvan Hastanesi',
      'en': 'Pelitli Animal Hospital',
      'ar': 'مستشفى بيليتلي للحيوانات',
    },
    'center_role_title': {
      'tr': 'Merkez Ne İşe Yarar, Neler Yapılır?',
      'en': 'What Does the Center Do?',
      'ar': 'ما هي مهام المركز وماذا يقدم؟',
    },
    'center_role_desc': {
      'tr': 'Gebze Belediyesi Sokak Hayvanları Rehabilitasyon ve Eğitim Merkezi; sokak hayvanlarımızın sağlık taramaları, kısırlaştırma operasyonları, aşılama ve kuduz mücadeleleri, iç-dış parazit tedavileri ile mikroçip kayıt işlemlerini modern tıbbi standartlarda gerçekleştirmektedir.\n\nAyrıca merkez bünyesinde hayvan hakları ve sevgisi konusunda çocuklara ve öğrencilere yönelik çevre & bilinçlendirme eğitimleri, sahiplendirme bahçesi ve doğal serbest dolaşım alanları bulunmaktadır.',
      'en': 'Gebze Municipality Stray Animals Rehabilitation & Training Center conducts health screenings, neutering operations, vaccinations, anti-rabies treatments, parasite treatments, and microchip registration under modern medical standards.\n\nFurthermore, the center hosts awareness workshops on animal rights for students, an adoption garden, and free roaming areas.',
      'ar': 'يقوم مركز بلدية جبزة لإعادة تأهيل وتدريب حيوانات الشارع بالفحوصات الطبية وعمليات التعقيم والتطعيم ومكافحة داء الكلب وعلاج الطفيليات وتسجيل الشرائح الإلكترونية بأحدث المعايير الطبية.\n\nكما يضم المركز ورش توعية بحقوق الحيوان للطلاب وحديقة تبني ومناطق تجوال طبيعية.',
    },
    'center_open_address': {
      'tr': 'Açık Adres',
      'en': 'Address',
      'ar': 'العنوان الكامل',
    },
    'center_phone_label': {'tr': 'Telefon', 'en': 'Phone', 'ar': 'الهاتف'},
    'btn_visit_website': {
      'tr': 'Belediye Web Sitesini Ziyaret Et (gebze.bel.tr)',
      'en': 'Visit Municipality Website (gebze.bel.tr)',
      'ar': 'زيارة موقع البلدية الرسمي (gebze.bel.tr)',
    },
    'visiting_hours_title': {
      'tr': 'Ziyaret ve İşlem Saatleri',
      'en': 'Visiting & Service Hours',
      'ar': 'ساعات الزيارة والمعاملات',
    },
    'day_mon': {'tr': 'Pazartesi', 'en': 'Monday', 'ar': 'الاثنين'},
    'day_tue': {'tr': 'Salı', 'en': 'Tuesday', 'ar': 'الثلاثاء'},
    'day_wed': {'tr': 'Çarşamba', 'en': 'Wednesday', 'ar': 'الأربعاء'},
    'day_thu': {'tr': 'Perşembe', 'en': 'Thursday', 'ar': 'الخميس'},
    'day_fri': {'tr': 'Cuma', 'en': 'Friday', 'ar': 'الجمعة'},
    'day_sat': {'tr': 'Cumartesi', 'en': 'Saturday', 'ar': 'السبت'},
    'day_sun': {'tr': 'Pazar', 'en': 'Sunday', 'ar': 'الأحد'},
    'closed_emergency_except': {
      'tr': 'Kapalı (Acil Servis Hariç)',
      'en': 'Closed (Except Emergency)',
      'ar': 'مغلق (باستثناء الطوارئ)',
    },
    'ambulance_shift_note': {
      'tr': '* Acil hayvan ambulansı ve nöbetçi veteriner acil vaka birimi çalışma saatleri dışındaki acil ihbarlarda da görev başındadır.',
      'en': '* Emergency pet ambulance and on-duty veterinary response unit are on duty outside working hours for emergencies.',
      'ar': '* تعمل سيارة إسعاف الحيوانات والوحدة البيطرية المناوبة خارج ساعات العمل للبلاغات الطارئة.',
    },

    // ───────────────────────── Sahiplendirme İlave ─────────────────────────
    'adoption_process_title': {
      'tr': 'Sahiplendirme Süreci Nasıl İşler?',
      'en': 'How Does Adoption Work?',
      'ar': 'كيف تسير عملية التبني؟',
    },
    'step1_title': {
      'tr': 'Dostunuzu Seçin & Arayın',
      'en': 'Choose Your Friend & Call',
      'ar': 'اختر صديقك واتصل',
    },
    'step1_desc': {
      'tr': 'Uygulamadan ilanı inceleyin ve "Telefon Et" butonu ile belediye merkezimizle görüşün.',
      'en': 'Browse listings in the app and contact our center using the "Call" button.',
      'ar': 'تصفح الإعلان في التطبيق وتواصل مع مركزنا بالضغط على "اتصال".',
    },
    'step2_title': {
      'tr': 'Merkezimizi Ziyaret Edin',
      'en': 'Visit Our Center',
      'ar': 'تفضل بزيارة مركزنا',
    },
    'step2_desc': {
      'tr': "Pelitli Sokak Hayvanları Rehabilitasyon Merkezi'ne gelip can dostumuzla tanışın.",
      'en': 'Come to Pelitli Animal Rehabilitation Center and meet your furry friend.',
      'ar': 'تفضل بزيارة مركز بيليتلي لإعادة تأهيل الحيوانات وتعرف على صديقك.',
    },
    'step3_title': {
      'tr': 'Kimlik & Sahiplendirme Sözleşmesi',
      'en': 'ID & Adoption Agreement',
      'ar': 'الهوية وعقد التبني',
    },
    'step3_desc': {
      'tr': '18 yaşını doldurmuş vatandaşlarımız kimlik belgesiyle ücretsiz sahiplendirme formunu doldurur.',
      'en': 'Citizens aged 18 and older fill out the free adoption form with their ID.',
      'ar': 'يملأ المواطنون فوق سن 18 عاماً استمارة التبني المجانية ببطاقة الهوية.',
    },
    'step4_title': {
      'tr': 'Aşı, Çip & Yuvasına Yolculuk',
      'en': 'Vaccine, Chip & Journey Home',
      'ar': 'التطعيم والشريحة والعودة للمنزل',
    },
    'step4_desc': {
      'tr': 'Mikroçip, aşı karnesi ve pasaportu belediye veteriner hekimlerimizce teslim edilip dostunuz evinize uğurlanır.',
      'en': 'Microchip, vaccination card, and passport are handed over by our veterinarians to send your friend home.',
      'ar': 'يقوم أطباؤنا البيطريون بتسليم الشريحة وبطاقة التطعيم وجواز السفر لمرافقة صديقك للمنزل.',
    },
    'free_adoption_badge': {
      'tr': 'Belediyemizde sahiplendirme tamamen ücretsizdir.',
      'en': 'Adoption is completely free in our municipality.',
      'ar': 'التبني مجاني بالكامل في بلديتنا.',
    },
    'pet_dog': {'tr': 'Köpek', 'en': 'Dog', 'ar': 'كلب'},
    'pet_cat': {'tr': 'Kedi', 'en': 'Cat', 'ar': 'قطة'},
    'looking_for_home': {
      'tr': 'Yuva Arıyor',
      'en': 'Looking for Home',
      'ar': 'يبحث عن مأوى',
    },
    'adopt_contact_label': {
      'tr': 'Sahiplenmek İçin:',
      'en': 'To Adopt:',
      'ar': 'للتبني:',
    },
    'adopt_center_name': {
      'tr': 'Gebze Hayvan Merkezi',
      'en': 'Gebze Animal Center',
      'ar': 'مركز جبزة لرعاية الحيوانات',
    },

    // ───────────────────────── Mama & Klinikler İlave ─────────────────────────
    'feeding_network_title': {
      'tr': 'Gebze Mama & Su Odakları Ağı',
      'en': 'Gebze Food & Water Points Network',
      'ar': 'شبكة نقاط الطعام والماء في جبزة',
    },
    'feeding_network_sub': {
      'tr': 'Belediyemizin mahalle odaklı besleme ve su noktaları',
      'en': 'Neighborhood feeding and water stations by our municipality',
      'ar': 'محطات توزيع الطعام والماء في الأحياء من بلديتنا',
    },
    'feeding_network_desc': {
      'tr': 'Gebze genelinde sokak hayvanlarımızın sağlıklı beslenmesi ve taze suya erişimi için kurulan istasyonlar periyodik olarak temizlenmekte ve mama takviyesi yapılmaktadır.',
      'en': 'Stations established across Gebze for street animals are regularly cleaned and supplied with food and water.',
      'ar': 'يتم تنظيف المحطات المقامة في أنحاء جبزة وتزويدها بالطعام والماء النقي بانتظام.',
    },
    'equipment_label': {
      'tr': 'Neler Var:',
      'en': 'Features:',
      'ar': 'المحتويات:',
    },
    'duty_clinics_title': {
      'tr': 'Sahipli Evcil Hayvanlar İçin Nöbetçi Klinikler',
      'en': 'On-Duty Clinics for Pets',
      'ar': 'عيادات مناوبة للحيوانات الأليفة',
    },
    'duty_clinics_desc': {
      'tr': 'Evcil can dostunuzun acil sağlık durumlarında Gebze genelinde 7/24 veya gece saatlerinde hizmet veren özel nöbetçi veteriner klinikleri listesi ve iletişim bilgileri.',
      'en': 'Directory and contacts for 24/7 or night-duty veterinary clinics across Gebze for pet health emergencies.',
      'ar': 'دليل وتواصل العيادات البيطرية الخاصة التي تقدم خدمات 24/7 أو ليلاً في جبزة لحالات الطوارئ.',
    },
    'no_duty_clinics': {
      'tr': 'Kayıtlı nöbetçi veteriner kliniği bulunamadı.',
      'en': 'No registered on-duty veterinary clinics found.',
      'ar': 'لم يتم العثور على عيادات بيطرية مناوبة مسجلة.',
    },

    // ───────────────────────── E-Belediye İlave ─────────────────────────
    'ebelediye_guide_title': {
      'tr': 'Online Belediye İşlemleri Rehberi',
      'en': 'Online Municipal Services Guide',
      'ar': 'دليل الخدمات البلدية الإلكترونية',
    },
    'ebelediye_guide_desc': {
      'tr': 'Gebze Belediyesi online borç sorgulama, e-beyan ve ruhsat işlemleri resmi e-Devlet ve Gebze Belediyesi portalları üzerinden kimlik doğrulaması gerektirmektedir. İlgili hizmeti seçip "İşleme Başla" butonu ile resmi sayfaya yönlendirilirsiniz.',
      'en': 'Gebze Municipality debt inquiry, e-declaration, and permit services require identity verification via e-Devlet and municipal portals. Select the service and click "Start Action" to proceed.',
      'ar': 'تتطلب معاملات الديون والإقرارات والتراخيص لبلدية جبزة التحقق عبر بوابة e-Devlet وبوابة البلدية الرسمية. اختر الخدمة واضغط على "بدء المعاملة" للمتابعة.',
    },
    'ebelediye_search_hint_full': {
      'tr': 'Hizmet veya işlem ara (vergi, beyan, imar...)',
      'en': 'Search service or transaction (tax, permit, zoning...)',
      'ar': 'ابحث عن خدمة أو معاملة (ضريبة، إقرار، تنظيم...)',
    },
    'ebelediye_empty_search': {
      'tr': 'Aramanızla eşleşen e-belediye hizmeti bulunamadı.',
      'en': 'No e-municipality service found matching your search.',
      'ar': 'لم يتم العثور على خدمات بلدية مطابقة لبحثك.',
    },
    'ebelediye_redirect_fallback': {
      'tr': 'Bu işlem için Gebze Belediyesi resmi web sayfasına yönlendirileceksiniz.',
      'en': 'You will be redirected to the official Gebze Municipality portal for this action.',
      'ar': 'سيتم توجيهك إلى بوابة بلدية جبزة الرسمية لإتمام هذه المعاملة.',
    },
    'select_action_type_sub': {
      'tr': 'Lütfen yapmak istediğiniz işlem türünü seçiniz:',
      'en': 'Please select the type of transaction you wish to perform:',
      'ar': 'يرجى اختيار نوع المعاملة التي ترغب بإجرائها:',
    },

    // ───────────────────────── Profil İlave ─────────────────────────
    'change_avatar_title': {
      'tr': 'Profil Resmi Değiştir',
      'en': 'Change Profile Picture',
      'ar': 'تغيير صورة الملف الشخصي',
    },
    'change_avatar_sub': {
      'tr': 'Profil resminiz için bir görsel bağlantısı (URL) girebilirsiniz:',
      'en': 'You can enter an image URL for your profile picture:',
      'ar': 'يمكنك إدخال رابط صورة (URL) لملفك الشخصي:',
    },
    'avatar_updated_toast': {
      'tr': 'Profil resmi güncellendi.',
      'en': 'Profile picture updated.',
      'ar': 'تم تحديث صورة الملف الشخصي.',
    },
    'theme_picker_title': {
      'tr': 'Tema Tercihini Seçin',
      'en': 'Select Theme Preference',
      'ar': 'اختر مظهر التطبيق',
    },
    'theme_updated_toast': {
      'tr': 'Tema tercihi güncellendi.',
      'en': 'Theme preference updated.',
      'ar': 'تم تحديث مظهر التطبيق.',
    },
    'no_activities_found': {
      'tr': 'Henüz bu kategoride aktiviteniz yok',
      'en': 'No activities in this category yet',
      'ar': 'لا توجد نشاطات في هذه الفئة بعد',
    },
    'call_failed_toast': {
      'tr': 'Telefon araması başlatılamadı: {0}',
      'en': 'Could not start call: {0}',
      'ar': 'تعذر بدء الاتصال الهاتفي: {0}',
    },
  };

  /// Belirli bir anahtar ve dil için çeviriyi döndürür
  static String get(String key, String lang) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['tr'] ?? key;
  }

  /// Hava durumu durum metinlerini çevirir
  static String translateWeatherCondition(String condition, String lang) {
    final c = condition.toLowerCase().trim();
    if (c.contains('güneş') ||
        c.contains('açık') ||
        c.contains('sunny') ||
        c.contains('clear')) {
      if (lang == 'en') return 'Sunny';
      if (lang == 'ar') return 'مشمس';
      return 'Güneşli';
    }
    if (c.contains('az bulut') ||
        c.contains('parçalı') ||
        c.contains('partly')) {
      if (lang == 'en') return 'Partly Cloudy';
      if (lang == 'ar') return 'غائم جزئياً';
      return 'Parçalı Bulutlu';
    }
    if (c.contains('bulut') || c.contains('cloud') || c.contains('overcast')) {
      if (lang == 'en') return 'Cloudy';
      if (lang == 'ar') return 'غائم';
      return 'Çok Bulutlu';
    }
    if (c.contains('yağmur') ||
        c.contains('rain') ||
        c.contains('drizzle') ||
        c.contains('sağanak')) {
      if (lang == 'en') return 'Rainy';
      if (lang == 'ar') return 'ممطر';
      return 'Yağmurlu';
    }
    if (c.contains('kar') || c.contains('snow') || c.contains('blizzard')) {
      if (lang == 'en') return 'Snowy';
      if (lang == 'ar') return 'مثلج';
      return 'Karlı';
    }
    if (c.contains('fırtına') || c.contains('storm') || c.contains('thunder')) {
      if (lang == 'en') return 'Thunderstorm';
      if (lang == 'ar') return 'عاصفة رعدية';
      return 'Gök Gürültülü Fırtına';
    }
    if (c.contains('sis') ||
        c.contains('pus') ||
        c.contains('fog') ||
        c.contains('mist')) {
      if (lang == 'en') return 'Foggy';
      if (lang == 'ar') return 'ضبابي';
      return 'Sisli';
    }
    if (lang == 'en') return condition;
    return condition;
  }

  /// Haftanın günlerini çevirir (1: Pazartesi ... 7: Pazar)
  static String getDayName(int weekday, String lang) {
    const days = {
      1: {'tr': 'Pazartesi', 'en': 'Monday', 'ar': 'الاثنين'},
      2: {'tr': 'Salı', 'en': 'Tuesday', 'ar': 'الثلاثاء'},
      3: {'tr': 'Çarşamba', 'en': 'Wednesday', 'ar': 'الأربعاء'},
      4: {'tr': 'Perşembe', 'en': 'Thursday', 'ar': 'الخميس'},
      5: {'tr': 'Cuma', 'en': 'Friday', 'ar': 'الجمعة'},
      6: {'tr': 'Cumartesi', 'en': 'Saturday', 'ar': 'السبت'},
      7: {'tr': 'Pazar', 'en': 'Sunday', 'ar': 'الأحد'},
    };
    return days[weekday]?[lang] ?? days[weekday]?['tr'] ?? '';
  }
}

/// Kolay kullanım için BuildContext extension'ı
extension AppLocalizationsExt on BuildContext {
  String tr(String key, [WidgetRef? ref]) {
    String lang = 'tr';
    if (ref != null) {
      lang = ref.watch(appLanguageProvider);
    } else {
      try {
        lang = Localizations.localeOf(this).languageCode;
      } catch (_) {
        lang = 'tr';
      }
    }
    return AppStrings.get(key, lang);
  }

  String get currentLang {
    try {
      return Localizations.localeOf(this).languageCode;
    } catch (_) {
      return 'tr';
    }
  }
}
