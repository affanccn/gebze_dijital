import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/municipal_news.dart';
import '../services/news_service.dart';
import '../news_preview_screen.dart';
import '../../../../core/localization/app_strings.dart';

class MunicipalNewsList extends ConsumerStatefulWidget {
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
  ConsumerState<MunicipalNewsList> createState() => _MunicipalNewsListState();
}

class _MunicipalNewsListState extends ConsumerState<MunicipalNewsList> {
  // Stream bir kez oluşturulur: ekran yeniden çizilince tekrar okuma yapılmaz,
  // liste de yanıp sönmez. Sadece son 10 haber gösterilir.
  late final Stream<List<MunicipalNews>> _stream = NewsService().watchNews(
    limit: widget.itemLimit ?? 10,
  );

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<MunicipalNews>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Haber akışı hatası: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.get('news_load_failed', lang),
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF5F6F8A),
                ),
              ),
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.get('news_empty_text', lang),
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF5F6F8A),
                ),
              ),
            ),
          );
        }

        final listView = ListView.builder(
          scrollDirection: widget.isHorizontal
              ? Axis.horizontal
              : Axis.vertical,
          shrinkWrap: widget.shrinkWrap && !widget.isHorizontal,
          // Tam ekran haber sayfasında sistem üst boşluğunu kaldır (başlık SafeArea'yı zaten karşılıyor).
          padding: (!widget.shrinkWrap && !widget.isHorizontal)
              ? const EdgeInsets.only(top: 8, bottom: 24)
              : null,
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: widget.isHorizontal ? 120 : 100,
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5FD),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Directionality(
                      textDirection: lang == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.localizedTitle(lang),
                            style: TextStyle(
                              fontSize: widget.isHorizontal ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0A1F44),
                              height: 1.35,
                            ),
                            maxLines: widget.isHorizontal ? 3 : null,
                            overflow: widget.isHorizontal
                                ? TextOverflow.ellipsis
                                : null,
                          ),
                          if (item.publishedAtText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.localizedDate(lang),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF5F6F8A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            final card = Card(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: isDark ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark
                    ? const BorderSide(color: Color(0xFF334155))
                    : BorderSide.none,
              ),
              margin: widget.isHorizontal
                  ? EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == news.length - 1 ? 16 : 8,
                      top: 6,
                      bottom: 6,
                    )
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: cardContent,
            );

            if (widget.isHorizontal) {
              return SizedBox(width: 240, child: card);
            }

            return card;
          },
        );

        if (widget.isHorizontal) {
          return SizedBox(height: 260, child: listView);
        }

        return listView;
      },
    );
  }
}
