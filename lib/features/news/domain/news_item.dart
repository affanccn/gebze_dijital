import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.url,
    this.imageUrl,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;

  static const _months = [
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

  String? get dateLabel {
    final d = publishedAt;
    if (d == null) return null;
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  factory NewsItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return NewsItem(
      id: doc.id,
      title: d['title'] as String? ?? '',
      url: d['url'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate(),
    );
  }
}
