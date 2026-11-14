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

  static DateTime? _parseTrDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final match = RegExp(r'(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})')
        .firstMatch(raw);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!) ?? 1;
    final monthStr = match.group(2)!.toLowerCase();
    final year = int.tryParse(match.group(3)!) ?? 2026;
    const mList = [
      'ocak',
      'şubat',
      'mart',
      'nisan',
      'mayıs',
      'haziran',
      'temmuz',
      'ağustos',
      'eylül',
      'ekim',
      'kasım',
      'aralık',
    ];
    final mIdx = mList.indexOf(monthStr);
    final month = mIdx != -1 ? mIdx + 1 : 10;
    return DateTime(year, month, day);
  }

  factory NewsItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? dt = (d['publishedAt'] as Timestamp?)?.toDate();
    if (dt == null) {
      final pText = (d['publishedAtText'] as String? ?? '').trim();
      if (pText.isNotEmpty && pText.toLowerCase() != 'güncel') {
        dt = _parseTrDate(pText);
      }
    }
    dt ??=
        (d['syncedAt'] as Timestamp?)?.toDate() ??
        (d['createdAt'] as Timestamp?)?.toDate();
    dt ??= DateTime(2026, 10, 26);

    return NewsItem(
      id: doc.id,
      title: d['title'] as String? ?? '',
      url: d['url'] as String? ?? '',
      imageUrl: (d['image'] as String?) ?? (d['imageUrl'] as String?),
      publishedAt: dt,
    );
  }
}
