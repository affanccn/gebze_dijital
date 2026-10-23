class MunicipalNews {
  final String id;
  final String title;
  final String image;
  final String url;
  final String publishedAtText;
  final int pageIndex;
  final int itemIndex;
  final String summary;
  final String? titleEn;
  final String? titleAr;
  final String? summaryEn;
  final String? summaryAr;

  const MunicipalNews({
    required this.id,
    required this.title,
    required this.image,
    required this.url,
    required this.publishedAtText,
    required this.pageIndex,
    required this.itemIndex,
    this.summary = '',
    this.titleEn,
    this.titleAr,
    this.summaryEn,
    this.summaryAr,
  });

  factory MunicipalNews.fromMap(String id, Map<String, dynamic> data) {
    return MunicipalNews(
      id: id,
      title: data['title'] as String? ?? '',
      image: data['image'] as String? ?? '',
      url: data['url'] as String? ?? '',
      publishedAtText: data['publishedAtText'] as String? ?? '',
      pageIndex: (data['pageIndex'] as num?)?.toInt() ?? 999,
      itemIndex: (data['itemIndex'] as num?)?.toInt() ?? 999,
      summary: data['summary'] as String? ??
          data['description'] as String? ??
          data['content'] as String? ??
          '',
      titleEn: data['title_en'] as String?,
      titleAr: data['title_ar'] as String?,
      summaryEn: data['summary_en'] as String?,
      summaryAr: data['summary_ar'] as String?,
    );
  }

  /// Aktif dile göre başlığı döndürür ('tr', 'en', 'ar')
  String localizedTitle(String lang) {
    if (lang == 'en' &&
        titleEn != null &&
        titleEn!.trim().isNotEmpty &&
        titleEn != title) {
      return titleEn!;
    }
    if (lang == 'ar' &&
        titleAr != null &&
        titleAr!.trim().isNotEmpty &&
        titleAr != title) {
      return titleAr!;
    }
    return title;
  }

  /// Aktif dile göre haber özetini döndürür ('tr', 'en', 'ar')
  /// Eğer hedef dildeki özet henüz yoksa boş string döner ki dinamik çeviri veya fallback devreye girsin.
  String localizedSummary(String lang) {
    if (lang == 'en') {
      if (summaryEn != null &&
          summaryEn!.trim().isNotEmpty &&
          summaryEn != summary) {
        return summaryEn!;
      }
      return '';
    }
    if (lang == 'ar') {
      if (summaryAr != null &&
          summaryAr!.trim().isNotEmpty &&
          summaryAr != summary) {
        return summaryAr!;
      }
      return '';
    }
    return summary;
  }

  /// Haber tarihini aktif dile göre formatlar ('21 Ekim 2026' -> '21 أكتوبر 2026' veya 'October 21, 2026')
  String localizedDate(String lang) {
    if (publishedAtText.isEmpty) return publishedAtText;
    final match = RegExp(
      r'(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})',
    ).firstMatch(publishedAtText);
    if (match == null) return publishedAtText;

    final day = match.group(1)!;
    final rawMonth = match.group(2)!.toLowerCase();
    final year = match.group(3)!;

    const monthMap = {
      'ocak': {'en': 'January', 'ar': 'يناير'},
      'şubat': {'en': 'February', 'ar': 'فبراير'},
      'mart': {'en': 'March', 'ar': 'مارس'},
      'nisan': {'en': 'April', 'ar': 'أبريل'},
      'mayıs': {'en': 'May', 'ar': 'مايو'},
      'haziran': {'en': 'June', 'ar': 'يونيو'},
      'temmuz': {'en': 'July', 'ar': 'يوليو'},
      'ağustos': {'en': 'August', 'ar': 'أغسطس'},
      'eylül': {'en': 'September', 'ar': 'سبتمبر'},
      'ekim': {'en': 'October', 'ar': 'أكتوبر'},
      'kasım': {'en': 'November', 'ar': 'نوفمبر'},
      'aralık': {'en': 'December', 'ar': 'ديسمبر'},
    };

    final entry = monthMap[rawMonth];
    if (entry == null) return publishedAtText;

    if (lang == 'en') {
      return '${entry['en']} $day, $year';
    }
    if (lang == 'ar') {
      return '$day ${entry['ar']} $year';
    }
    return publishedAtText;
  }
}


