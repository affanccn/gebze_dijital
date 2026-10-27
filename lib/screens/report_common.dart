import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/services/profile_service.dart' show kCurrentUserId;

/// Çek & Gönder / Taleplerim ortak sabitleri, durumlar ve veri erişimi.
/// Dosya yolu: lib/screens/report_common.dart

class RC {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFE5231B);
  static const green = Color(0xFF2E7D32);
  static const blue = Color(0xFF1565C0);
  static const border = Color(0xFFE4E9F2);
}

const List<String> kReportNeighborhoods = [
  'Mustafapaşa',
  'Osman Yılmaz',
  'Arapçeşme',
  'Hacıhalil',
  'Mevlana',
  'Gaziler',
  'Eskihisar',
  'Köşklü Çeşme',
  'Güzeller',
  'Yenikent',
  'İnönü',
  'İstasyon',
  'Tatlıkuyu',
  'Barış',
  'Kirazpınar',
  'Sultan Orhan',
  'Ulus',
  'Yavuz Selim',
  'Cumhuriyet',
  'Beylikbağı',
  'Hürriyet',
  'Mimar Sinan',
];

class ReportCategory {
  final String key;
  final IconData icon;
  const ReportCategory(this.key, this.icon);
}

const List<ReportCategory> kReportCategories = [
  ReportCategory('pothole', Icons.edit_road_rounded),
  ReportCategory('garbage', Icons.delete_outline_rounded),
  ReportCategory('pavement', Icons.directions_walk_rounded),
  ReportCategory('lighting', Icons.lightbulb_outline_rounded),
  ReportCategory('water', Icons.water_drop_outlined),
  ReportCategory('park', Icons.park_outlined),
  ReportCategory('other', Icons.more_horiz_rounded),
];

/// Dahili durum anahtarları (sıralı).
const List<String> kReportStatuses = [
  'pending',
  'reviewing',
  'in_progress',
  'resolved',
  'rejected',
];

/// Firestore'a yazılan Türkçe durum etiketleri (suggestions koleksiyonundaki
/// `status: "Beklemede"` düzeniyle aynı). Yönetim paneli bu değerleri yazmalı.
const Map<String, String> kReportStatusTr = {
  'pending': 'Beklemede',
  'reviewing': 'İnceleniyor',
  'in_progress': 'İşleme Alındı',
  'resolved': 'Çözüldü',
  'rejected': 'Reddedildi',
};

/// Türkçe karakterleri sadeleştirip küçük harfe çevirir.
String foldTr(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('\u0307', '')
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll('mahallesi', '')
    .replaceAll('mah.', '')
    .trim();

/// Firestore'daki ham `status` değerini (TR/EN, büyük-küçük harf fark etmez)
/// dahili anahtara çevirir.
String reportStatusKey(dynamic raw) {
  final f = foldTr((raw ?? '').toString());
  if (f.contains('cozul') || f.contains('resolved') || f.contains('tamam')) {
    return 'resolved';
  }
  if (f.contains('red') || f.contains('reject')) return 'rejected';
  if (f.contains('isleme') || f.contains('islemde') || f.contains('progress')) {
    return 'in_progress';
  }
  if (f.contains('incele') || f.contains('review')) return 'reviewing';
  return 'pending';
}

Color reportStatusColor(String s) {
  switch (s) {
    case 'reviewing':
      return RC.blue;
    case 'in_progress':
      return RC.orange;
    case 'resolved':
      return RC.green;
    case 'rejected':
      return RC.danger;
    default:
      return RC.textMuted;
  }
}

IconData reportStatusIcon(String s) {
  switch (s) {
    case 'reviewing':
      return Icons.search_rounded;
    case 'in_progress':
      return Icons.construction_rounded;
    case 'resolved':
      return Icons.check_circle_rounded;
    case 'rejected':
      return Icons.cancel_rounded;
    default:
      return Icons.hourglass_top_rounded;
  }
}

// ───────────────────────── Kimlik & Veri ─────────────────────────

/// Oturum süresince kullanıcının yerel olarak oluşturduğu raporlar
final List<Map<String, dynamic>> localSubmittedReports = [];

final List<Map<String, dynamic>> _fallbackReports = [
  {
    '_id': 'rep_sample_1',
    'ticketNo': 'GBD-2026-88192',
    'userId': 'default_citizen',
    'category': 'Temizlik',
    'categoryKey': 'garbage',
    'description': 'Cumhuriyet Mah. 1205. Sokak çöp konteyneri kapağı hasarlı, değiştirilmesini rica ediyorum.',
    'neighborhood': 'Cumhuriyet',
    'address': 'Cumhuriyet Mah. 1205. Sokak No: 14',
    'status': 'İşleme Alındı',
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    'statusHistory': [
      {
        'status': 'Beklemede',
        'at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        ),
      },
      {
        'status': 'İşleme Alındı',
        'at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 12)),
        ),
      },
    ],
  },
  {
    '_id': 'rep_sample_2',
    'ticketNo': 'GBD-2026-74210',
    'userId': 'default_citizen',
    'category': 'Aydınlatma',
    'categoryKey': 'lighting',
    'description':
        'Hacıhalil Mah. Park içi yürüyüş yolu aydınlatma direkleri yanmıyor.',
    'neighborhood': 'Hacıhalil',
    'address': 'Hacıhalil Parkı İçi',
    'status': 'Çözüldü',
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 3, hours: 5)),
    ),
    'statusHistory': [
      {
        'status': 'Beklemede',
        'at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        ),
      },
      {
        'status': 'İşleme Alındı',
        'at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
      },
      {
        'status': 'Çözüldü',
        'at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
    ],
  },
  {
    '_id': 'rep_sample_3',
    'ticketNo': 'GBD-2026-61904',
    'userId': 'default_citizen',
    'category': 'Bozuk Yol',
    'categoryKey': 'pothole',
    'description': 'İstasyon Cad. No: 48 önünde derin çukur oluşmuş, araçlar için tehlike yaratıyor.',
    'neighborhood': 'İstasyon',
    'address': 'İstasyon Cad. No: 48',
    'status': 'Beklemede',
    'createdAt': Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 5, hours: 8)),
    ),
    'statusHistory': [
      {
        'status': 'Beklemede',
        'at': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5, hours: 8)),
        ),
      },
    ],
  },
];

/// Talepler, profil servisinin kullandığı kullanıcı kimliğiyle eşlenir
/// (`users/{kCurrentUserId}`). Böylece profildeki Taleplerim aynı kayıtları görür.
Future<String> getReportUserId() async => kCurrentUserId;

final reportUserIdProvider = FutureProvider<String>((ref) => getReportUserId());

/// Kullanıcının talepleri (en yeni üstte). Her öğede `_id` alanı bulunur.
final myReportsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  // İlk önce hemen mevcut yerel ve örnek verileri yay (Asla sonsuz dönen yükleniyor kalmaz)
  List<Map<String, dynamic>> combined = [
    ...localSubmittedReports,
    if (localSubmittedReports.isEmpty) ..._fallbackReports,
  ];
  yield combined;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Misafir kullanıcı durumunda Firestore'a yetkisiz istek atmayıp yerel veriyi koru
    return;
  }

  try {
    final stream = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: user.uid)
        .snapshots();

    await for (final snap in stream) {
      final remoteList = snap.docs
          .map((d) => {...d.data(), '_id': d.id})
          .toList();
      final all = [...localSubmittedReports, ...remoteList];
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final r in all) {
        final key = r['ticketNo']?.toString() ?? r['_id']?.toString() ?? '';
        if (key.isNotEmpty && seen.contains(key)) continue;
        if (key.isNotEmpty) seen.add(key);
        unique.add(r);
      }
      unique.sort((a, b) {
        final ta = a['createdAt'];
        final tb = b['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        if (ta is Timestamp) return 1;
        if (tb is Timestamp) return -1;
        return 0;
      });
      yield unique.isEmpty ? _fallbackReports : unique;
    }
  } catch (_) {
    // Ağ ya da Firestore yetki hatasında yerel veri zaten sağlandı
  }
});

final myReportCountProvider = Provider<int>(
  (ref) => ref.watch(myReportsProvider).value?.length ?? 0,
);

/// `photoUrl` (Storage) ya da `photoBase64` (yedek) alanından fotoğraf çizer.
Widget reportPhoto(
  Map<String, dynamic> data, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final placeholder = Container(
    width: width,
    height: height,
    color: RC.bg,
    child: const Icon(Icons.image_outlined, color: RC.textMuted),
  );
  final url = data['photoUrl']?.toString();
  final b64 = data['photoBase64']?.toString();
  if (url != null && url.isNotEmpty) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
  if (b64 != null && b64.isNotEmpty) {
    try {
      return Image.memory(
        base64Decode(b64),
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } catch (_) {}
  }
  return placeholder;
}

String fmtDateTime(dynamic ts) {
  DateTime? d;
  try {
    d = (ts as dynamic).toDate() as DateTime;
  } catch (_) {}
  if (d == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Basit çok dilli metin erişimi (tr / en / ar). Bulunamazsa tr'ye düşer.
String rt(String lang, String key) =>
    _strings[lang]?[key] ?? _strings['tr']![key] ?? key;

const Map<String, Map<String, String>> _strings = {
  'tr': {
    'title': 'Çek & Gönder',
    'step_photo': 'Fotoğraf',
    'step_location': 'Konum',
    'step_category': 'Kategori',
    'step_desc': 'Açıklama',
    'step_summary': 'Özet ve Gönder',
    'photo_hint': 'Sorunun fotoğrafını çekin veya galeriden seçin.',
    'btn_camera': 'Kamera',
    'btn_gallery': 'Galeri',
    'photo_change': 'Değiştir',
    'photo_required': 'Lütfen bir fotoğraf ekleyin.',
    'loc_auto': 'Otomatik algıla',
    'loc_manual': 'Mahalle seç',
    'loc_detecting': 'Konum algılanıyor...',
    'loc_detected': 'Konum alındı',
    'loc_retry': 'Tekrar dene',
    'loc_failed': 'Konum alınamadı. Mahalleyi elle seçebilirsiniz.',
    'loc_denied': 'Konum izni verilmedi. Ayarlardan izin verin veya mahalleyi elle seçin.',
    'loc_service_off': 'Konum servisi kapalı. Açın veya mahalleyi elle seçin.',
    'loc_neighborhood': 'Mahalle',
    'loc_required': 'Lütfen konumu algılayın veya mahalle seçin.',
    'cat_required': 'Lütfen bir kategori seçin.',
    'desc_hint': 'Sorunu kısaca anlatın (en az 10 karakter)',
    'desc_short': 'Açıklama en az 10 karakter olmalı.',
    'summary_title': 'Gönderim Özeti',
    'sum_category': 'Kategori',
    'sum_location': 'Konum',
    'sum_photo': 'Fotoğraf',
    'sum_photo_ok': 'Seçildi',
    'sum_desc': 'Açıklama',
    'btn_next': 'Devam',
    'btn_back': 'Geri',
    'btn_send': 'Gönder',
    'sent_title': 'Talebiniz alındı',
    'sent_body': 'Takip numaranız',
    'sent_hint': 'Durumunu Profil > Taleplerim bölümünden takip edebilirsiniz.',
    'btn_my_requests': 'Taleplerim',
    'btn_ok': 'Tamam',
    'error': 'Bir hata oluştu',
    'my_title': 'Taleplerim',
    'filter_all': 'Tümü',
    'filter_active': 'Devam Eden',
    'filter_done': 'Sonuçlanan',
    'empty': 'Henüz talebiniz yok',
    'empty_hint': 'Çek & Gönder ile ilk bildiriminizi oluşturun.',
    'login_required': 'Taleplerinizi görmek için giriş yapmalısınız.',
    'ticket': 'Takip No',
    'created': 'Oluşturulma',
    'history': 'Durum Geçmişi',
    'admin_note': 'Belediye Yanıtı',
    'status_pending': 'Beklemede',
    'status_reviewing': 'İnceleniyor',
    'status_in_progress': 'İşlemde',
    'status_resolved': 'Çözüldü',
    'status_rejected': 'Reddedildi',
    'cat_pothole': 'Bozuk Yol',
    'cat_garbage': 'Çöp / Temizlik',
    'cat_pavement': 'Kaldırım',
    'cat_lighting': 'Aydınlatma',
    'cat_water': 'Su / Kanalizasyon',
    'cat_park': 'Park / Yeşil Alan',
    'cat_other': 'Diğer',
  },
  'en': {
    'title': 'Snap & Send',
    'step_photo': 'Photo',
    'step_location': 'Location',
    'step_category': 'Category',
    'step_desc': 'Description',
    'step_summary': 'Summary & Send',
    'photo_hint': 'Take a photo of the problem or pick one from your gallery.',
    'btn_camera': 'Camera',
    'btn_gallery': 'Gallery',
    'photo_change': 'Change',
    'photo_required': 'Please add a photo.',
    'loc_auto': 'Auto-detect',
    'loc_manual': 'Pick neighborhood',
    'loc_detecting': 'Detecting location...',
    'loc_detected': 'Location detected',
    'loc_retry': 'Try again',
    'loc_failed':
        'Could not get location. You can pick the neighborhood manually.',
    'loc_denied':
        'Location permission denied. Allow it in settings or pick manually.',
    'loc_service_off': 'Location service is off. Turn it on or pick manually.',
    'loc_neighborhood': 'Neighborhood',
    'loc_required': 'Please detect your location or pick a neighborhood.',
    'cat_required': 'Please choose a category.',
    'desc_hint': 'Briefly describe the problem (min. 10 characters)',
    'desc_short': 'Description must be at least 10 characters.',
    'summary_title': 'Submission Summary',
    'sum_category': 'Category',
    'sum_location': 'Location',
    'sum_photo': 'Photo',
    'sum_photo_ok': 'Selected',
    'sum_desc': 'Description',
    'btn_next': 'Next',
    'btn_back': 'Back',
    'btn_send': 'Send',
    'sent_title': 'Request received',
    'sent_body': 'Your tracking number',
    'sent_hint': 'Track its status under Profile > My Requests.',
    'btn_my_requests': 'My Requests',
    'btn_ok': 'OK',
    'error': 'An error occurred',
    'my_title': 'My Requests',
    'filter_all': 'All',
    'filter_active': 'Active',
    'filter_done': 'Closed',
    'empty': 'No requests yet',
    'empty_hint': 'Create your first report with Snap & Send.',
    'login_required': 'Please sign in to see your requests.',
    'ticket': 'Ticket No',
    'created': 'Created',
    'history': 'Status History',
    'admin_note': 'Municipality Reply',
    'status_pending': 'Pending',
    'status_reviewing': 'Under review',
    'status_in_progress': 'In progress',
    'status_resolved': 'Resolved',
    'status_rejected': 'Rejected',
    'cat_pothole': 'Damaged Road',
    'cat_garbage': 'Garbage / Cleaning',
    'cat_pavement': 'Sidewalk',
    'cat_lighting': 'Lighting',
    'cat_water': 'Water / Sewage',
    'cat_park': 'Park / Green Area',
    'cat_other': 'Other',
  },
  'ar': {
    'title': 'صوّر وأرسل',
    'step_photo': 'الصورة',
    'step_location': 'الموقع',
    'step_category': 'الفئة',
    'step_desc': 'الوصف',
    'step_summary': 'الملخص والإرسال',
    'photo_hint': 'التقط صورة للمشكلة أو اخترها من المعرض.',
    'btn_camera': 'الكاميرا',
    'btn_gallery': 'المعرض',
    'photo_change': 'تغيير',
    'photo_required': 'يرجى إضافة صورة.',
    'loc_auto': 'تحديد تلقائي',
    'loc_manual': 'اختر الحي',
    'loc_detecting': 'جارٍ تحديد الموقع...',
    'loc_detected': 'تم تحديد الموقع',
    'loc_retry': 'إعادة المحاولة',
    'loc_failed': 'تعذر تحديد الموقع. يمكنك اختيار الحي يدوياً.',
    'loc_denied': 'تم رفض إذن الموقع. فعّله من الإعدادات أو اختر الحي يدوياً.',
    'loc_service_off': 'خدمة الموقع متوقفة. شغّلها أو اختر الحي يدوياً.',
    'loc_neighborhood': 'الحي',
    'loc_required': 'يرجى تحديد الموقع أو اختيار الحي.',
    'cat_required': 'يرجى اختيار فئة.',
    'desc_hint': 'صف المشكلة باختصار (10 أحرف على الأقل)',
    'desc_short': 'يجب أن يكون الوصف 10 أحرف على الأقل.',
    'summary_title': 'ملخص الإرسال',
    'sum_category': 'الفئة',
    'sum_location': 'الموقع',
    'sum_photo': 'الصورة',
    'sum_photo_ok': 'تم الاختيار',
    'sum_desc': 'الوصف',
    'btn_next': 'متابعة',
    'btn_back': 'رجوع',
    'btn_send': 'إرسال',
    'sent_title': 'تم استلام طلبك',
    'sent_body': 'رقم المتابعة',
    'sent_hint': 'يمكنك متابعة الحالة من الملف الشخصي > طلباتي.',
    'btn_my_requests': 'طلباتي',
    'btn_ok': 'حسناً',
    'error': 'حدث خطأ',
    'my_title': 'طلباتي',
    'filter_all': 'الكل',
    'filter_active': 'قيد المعالجة',
    'filter_done': 'المنتهية',
    'empty': 'لا توجد طلبات بعد',
    'empty_hint': 'أنشئ أول بلاغ لك عبر صوّر وأرسل.',
    'login_required': 'يجب تسجيل الدخول لعرض طلباتك.',
    'ticket': 'رقم المتابعة',
    'created': 'تاريخ الإنشاء',
    'history': 'سجل الحالة',
    'admin_note': 'رد البلدية',
    'status_pending': 'قيد الانتظار',
    'status_reviewing': 'قيد المراجعة',
    'status_in_progress': 'قيد التنفيذ',
    'status_resolved': 'تم الحل',
    'status_rejected': 'مرفوض',
    'cat_pothole': 'طريق متضرر',
    'cat_garbage': 'نفايات / نظافة',
    'cat_pavement': 'رصيف',
    'cat_lighting': 'إنارة',
    'cat_water': 'مياه / صرف صحي',
    'cat_park': 'حديقة / مساحة خضراء',
    'cat_other': 'أخرى',
  },
};
