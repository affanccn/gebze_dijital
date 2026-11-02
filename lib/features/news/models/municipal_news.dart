class MunicipalNews {
  final String id;
  final String title;
  final String image;
  final String url;
  final String publishedAtText;
  final int pageIndex;
  final int itemIndex;
  final String summary;
  final int? newsId;
  final String? titleEn;
  final String? titleAr;
  final String? summaryEn;
  final String? summaryAr;
  final String? category;
  final DateTime? createdAt;

  const MunicipalNews({
    required this.id,
    required this.title,
    required this.image,
    required this.url,
    required this.publishedAtText,
    required this.pageIndex,
    required this.itemIndex,
    this.newsId,
    this.summary = '',
    this.titleEn,
    this.titleAr,
    this.summaryEn,
    this.summaryAr,
    this.category,
    this.createdAt,
  });

  /// Sıralama anahtarı: Admin panelinden eklenen haberler (createdAt içeren veya
  /// newsId değeri yüksek/eksik olan kayıtlar) her zaman en üstte görünür.
  int get sortKey {
    if (createdAt != null && (newsId == null || newsId! > 100000)) {
      return createdAt!.millisecondsSinceEpoch ~/ 1000;
    }
    if (newsId != null && newsId! > 100000) {
      return newsId!;
    }
    if (newsId != null) {
      return newsId!;
    }
    if (createdAt != null) {
      return createdAt!.millisecondsSinceEpoch ~/ 1000;
    }
    return 2000000000;
  }

  factory MunicipalNews.fromMap(String id, Map<String, dynamic> data) {
    return MunicipalNews(
      id: id,
      title: data['title'] as String? ?? '',
      image: data['image'] as String? ?? data['imageUrl'] as String? ?? '',
      url: data['url'] as String? ?? '',
      publishedAtText: _resolveDateText(data),
      pageIndex: (data['pageIndex'] as num?)?.toInt() ?? 999,
      itemIndex: (data['itemIndex'] as num?)?.toInt() ?? 999,
      newsId: (data['newsId'] as num?)?.toInt(),
      summary: data['summary'] as String? ??
          data['description'] as String? ??
          data['content'] as String? ??
          '',
      titleEn: data['title_en'] as String?,
      titleAr: data['title_ar'] as String?,
      summaryEn: data['summary_en'] as String?,
      summaryAr: data['summary_ar'] as String?,
      category: data['category'] as String?,
      createdAt: _parseDateTime(data['createdAt'] ?? data['publishedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    try {
      return (raw as dynamic).toDate() as DateTime;
    } catch (_) {}
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static String _resolveDateText(Map<String, dynamic> data) {
    final raw = (data['publishedAtText'] as String? ?? '').trim();
    if (raw.isNotEmpty &&
        raw.toLowerCase() != 'güncel' &&
        RegExp(r'\d').hasMatch(raw)) {
      return raw;
    }

    const trMonths = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final ts = data['publishedAt'] ?? data['syncedAt'] ?? data['createdAt'];
    if (ts is DateTime) {
      final m = (ts.month >= 1 && ts.month <= 12) ? trMonths[ts.month] : 'Ekim';
      return '${ts.day} $m ${ts.year}';
    }
    // dynamic timestamp check (Firebase Timestamp)
    if (ts != null) {
      try {
        final d = (ts as dynamic).toDate() as DateTime;
        final m = (d.month >= 1 && d.month <= 12) ? trMonths[d.month] : 'Ekim';
        return '${d.day} $m ${d.year}';
      } catch (_) {}
    }

    final newsId = (data['newsId'] as num?)?.toInt();
    if (newsId != null) {
      if (newsId >= 7451) return '26 Ekim 2026';
      if (newsId >= 7449) return '25 Ekim 2026';
      if (newsId >= 7447) return '24 Ekim 2026';
      if (newsId >= 7445) return '23 Ekim 2026';
      if (newsId >= 7442) return '21 Ekim 2026';
      if (newsId >= 7440) return '20 Ekim 2026';
      if (newsId >= 7438) return '18 Ekim 2026';
      if (newsId >= 7436) return '17 Ekim 2026';
      if (newsId >= 7434) return '16 Ekim 2026';
      if (newsId >= 7432) return '15 Ekim 2026';
      if (newsId >= 7430) return '14 Ekim 2026';
      if (newsId >= 7428) return '13 Ekim 2026';
      if (newsId >= 7426) return '10 Ekim 2026';
      if (newsId >= 7424) return '09 Ekim 2026';
      if (newsId >= 7422) return '08 Ekim 2026';
      if (newsId >= 7418) return '07 Ekim 2026';
    }

    return '26 Ekim 2026';
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
    final effectiveText =
        (publishedAtText.trim().toLowerCase() == 'güncel' ||
            publishedAtText.trim().isEmpty)
        ? '26 Ekim 2026'
        : publishedAtText.trim();

    final match = RegExp(
      r'(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})',
    ).firstMatch(effectiveText);
    if (match == null) return effectiveText;

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
