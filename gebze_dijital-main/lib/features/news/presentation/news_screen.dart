import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/news_item.dart';
import 'providers/news_providers.dart';

const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(item.url),
            mode: LaunchMode.inAppBrowserView),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) =>
                      const Center(child: Icon(Icons.image_not_supported_outlined)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.publishedAt != null)
                    Text(_fmt(item.publishedAt!), style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(item.title, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}