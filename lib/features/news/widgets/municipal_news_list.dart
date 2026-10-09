import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/municipal_news.dart';
import '../services/news_service.dart';

class MunicipalNewsList extends StatefulWidget {
  const MunicipalNewsList({super.key, this.itemLimit, this.shrinkWrap = false});

  final int? itemLimit;
  final bool shrinkWrap;

  @override
  State<MunicipalNewsList> createState() => _MunicipalNewsListState();
}

class _MunicipalNewsListState extends State<MunicipalNewsList> {
  // Stream bir kez oluşturulur: ekran yeniden çizilince tekrar okuma yapılmaz,
  // liste de yanıp sönmez.
  late final Stream<List<MunicipalNews>> _stream = NewsService().watchNews(
    limit: widget.itemLimit ?? 100,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MunicipalNews>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Haber akışı hatası: ${snapshot.error}');
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Haberler yüklenemedi.'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final news = snapshot.data!;

        if (news.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Henüz haber bulunmuyor.'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: widget.shrinkWrap,
          physics: widget.shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : null,
          itemCount: news.length,
          itemBuilder: (context, index) {
            final item = news[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  final uri = Uri.tryParse(item.url);

                  if (uri != null &&
                      uri.scheme == 'https' &&
                      (uri.host == 'gebze.bel.tr' ||
                          uri.host == 'www.gebze.bel.tr')) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.image.isNotEmpty)
                      Image.network(
                        item.image,
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 100,
                          child: Center(child: Icon(Icons.image_not_supported)),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (item.publishedAtText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.publishedAtText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text('Haberi oku →'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}