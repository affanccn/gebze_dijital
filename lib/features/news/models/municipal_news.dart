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
    if (lang == 'en' && titleEn != null && titleEn!.trim().isNotEmpty) {
      return titleEn!;
    }
    if (lang == 'ar' && titleAr != null && titleAr!.trim().isNotEmpty) {
      return titleAr!;
    }
    return title;
  }

  /// Aktif dile göre haber özetini döndürür ('tr', 'en', 'ar')
  String localizedSummary(String lang) {
    if (lang == 'en' && summaryEn != null && summaryEn!.trim().isNotEmpty) {
      return summaryEn!;
    }
    if (lang == 'ar' && summaryAr != null && summaryAr!.trim().isNotEmpty) {
      return summaryAr!;
    }
    return summary;
  }
}

