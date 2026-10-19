class MunicipalNews {
  final String id;
  final String title;
  final String image;
  final String url;
  final String publishedAtText;
  final int pageIndex;
  final int itemIndex;
  final String summary;

  const MunicipalNews({
    required this.id,
    required this.title,
    required this.image,
    required this.url,
    required this.publishedAtText,
    required this.pageIndex,
    required this.itemIndex,
    this.summary = '',
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
    );
  }
}
