import 'package:flutter/material.dart';

import '../models/municipal_news.dart';
import '../services/news_service.dart';
import '../news_preview_screen.dart';

class MunicipalNewsList extends StatefulWidget {
  const MunicipalNewsList({
    super.key,
    this.itemLimit,
    this.shrinkWrap = false,
    this.isHorizontal = false,
  });

  final int? itemLimit;
  final bool shrinkWrap;
  final bool isHorizontal;

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

        final listView = ListView.builder(
          scrollDirection: widget.isHorizontal ? Axis.horizontal : Axis.vertical,
          shrinkWrap: widget.shrinkWrap && !widget.isHorizontal,
          physics: widget.shrinkWrap && !widget.isHorizontal
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          itemCount: news.length,
          itemBuilder: (context, index) {
            final item = news[index];

            final cardContent = InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NewsPreviewScreen(news: item),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.image.isNotEmpty)
                    Image.network(
                      item.image,
                      width: double.infinity,
                      height: widget.isHorizontal ? 120 : 190,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => SizedBox(
                        height: widget.isHorizontal ? 120 : 100,
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: widget.isHorizontal ? 14 : null,
                              ),
                          maxLines: widget.isHorizontal ? 3 : null,
                          overflow: widget.isHorizontal ? TextOverflow.ellipsis : null,
                        ),
                        if (item.publishedAtText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.publishedAtText,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (widget.isHorizontal) {
              return SizedBox(
                width: 240,
                child: Card(
                  margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == news.length - 1 ? 16 : 8,
                      top: 6,
                      bottom: 6),
                  clipBehavior: Clip.antiAlias,
                  child: cardContent,
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: cardContent,
            );
          },
        );

        if (widget.isHorizontal) {
          return SizedBox(
            height: 260,
            child: listView,
          );
        }

        return listView;
      },
    );
  }
}
