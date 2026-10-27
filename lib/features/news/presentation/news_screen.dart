import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/news_item.dart';
import 'providers/news_providers.dart';

const _months = [
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

String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Haberler')),
      body: news.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Haberler yüklenemedi.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(newsListProvider),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Henüz haber yok.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _NewsCard(item: items[i]),
              ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? const BorderSide(color: Color(0xFF334155))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            launchUrl(Uri.parse(item.url), mode: LaunchMode.inAppBrowserView),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, _, _) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: isDark ? const Color(0xFF64748B) : Colors.grey,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.publishedAt != null)
                    Text(
                      _fmt(item.publishedAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF5F6F8A),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0A1F44),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
