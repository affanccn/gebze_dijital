import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gebze_dijital/features/news/models/municipal_news.dart';

import '../../core/localization/app_strings.dart';
import 'services/news_service.dart';

class NewsPreviewScreen extends ConsumerStatefulWidget {
  const NewsPreviewScreen({super.key, required this.news});

  final MunicipalNews news;

  @override
  ConsumerState<NewsPreviewScreen> createState() => _NewsPreviewScreenState();
}

class _NewsPreviewScreenState extends ConsumerState<NewsPreviewScreen> {
  String? _summary;
  String? _title;
  bool _isLoadingSummary = true;
  String _currentLang = '';

  @override
  void initState() {
    super.initState();
    final initialLang = ref.read(appLanguageProvider);
    _initForLang(initialLang);
  }

  void _initForLang(String lang) {
    _currentLang = lang;

    // 1. Başlık hazırlığı
    final locTitle = widget.news.localizedTitle(lang);
    if (lang != 'tr' && (locTitle == widget.news.title || locTitle.isEmpty)) {
      _title = widget.news.title;
      NewsService().translateText(widget.news.title, lang).then((transTitle) {
        if (mounted && transTitle != null && transTitle.isNotEmpty) {
          setState(() {
            _title = transTitle;
          });
        }
      });
    } else {
      _title = locTitle;
    }

    // 2. Özet hazırlığı
    final locSummary = widget.news.localizedSummary(lang);
    if (locSummary.isNotEmpty) {
      _summary = locSummary;
      _isLoadingSummary = false;
      return;
    }

    _loadSummary(lang);
  }

  Future<void> _loadSummary(String lang) async {
    setState(() {
      _isLoadingSummary = true;
    });

    final fetched = await NewsService().fetchNewsSummary(
      widget.news.url,
      title: widget.news.title,
    );

    if (!mounted) return;

    if (fetched != null && fetched.isNotEmpty) {
      if (lang == 'tr') {
        setState(() {
          _summary = fetched;
          _isLoadingSummary = false;
        });
      } else {
        final translated = await NewsService().translateText(fetched, lang);
        if (mounted) {
          setState(() {
            _summary = translated ?? _buildFallbackSummary(widget.news, lang);
            _isLoadingSummary = false;
          });
        }
      }
    } else {
      setState(() {
        _summary = _buildFallbackSummary(widget.news, lang);
        _isLoadingSummary = false;
      });
    }
  }

  String _buildFallbackSummary(MunicipalNews news, String lang) {
    final title = news.localizedTitle(lang);
    if (lang == 'en') {
      return '$title. Comprehensive municipal works carried out by Gebze Municipality teams to improve the quality of life of our citizens continue without interruption. You can tap the Read More button to access the official announcement, details, and photo gallery.';
    }
    if (lang == 'ar') {
      return '$title. تتواصل أعمال بلدية غبزة الشاملة لتحسين جودة حياة المواطنين وإضافة قيمة للمنطقة دون انقطاع. يمكنك الضغط على زر اقرأ المزيد للوصول إلى تفاصيل الخبر الكاملة ومعرض الصور على الموقع الرسمي.';
    }
    return '$title. Gebze Belediyesi ekipleri tarafından vatandaşlarımızın yaşam kalitesini artırmak ve ilçemize değer katmak amacıyla yürütülen kapsamlı çalışmalar aralıksız sürmektedir. Hizmet bülteni, teknik detaylar, yapılan uygulamalar ve ilgili fotoğraf galerisine ulaşarak haberin tam metnini okumak için Devamını Oku butonunu kullanabilirsiniz.';
  }

  Future<void> _openNewsDetail() async {
    final uri = Uri.tryParse(widget.news.url);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentLang != lang) {
      // Dil değiştiğinde ilgili dile ait özet ve başlığı yeniden başlat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initForLang(lang);
      });
    }

    final displayTitle = _title ?? widget.news.localizedTitle(lang);
    final displaySummary = _summary ?? _buildFallbackSummary(widget.news, lang);
    final displayDate = widget.news.localizedDate(lang);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5FD),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E5BC6), Color(0xFF0A2A66)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        AppStrings.get('news_preview_title', lang),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.news.image.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 50 : 20),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            widget.news.image,
                            width: double.infinity,
                            height: 230,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 180,
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 48,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: isDark
                            ? Border.all(color: const Color(0xFF334155))
                            : Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A2A66).withAlpha(isDark ? 30 : 14),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Directionality(
                        textDirection: lang == 'ar'
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A00).withAlpha(isDark ? 35 : 20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.newspaper_rounded,
                                    size: 14,
                                    color: Color(0xFFFF7A00),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.get('news_badge_title', lang),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF7A00),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayTitle,
                              style: TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0A1F44),
                                height: 1.35,
                              ),
                            ),
                          if (displayDate.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF5F6F8A),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  displayDate,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF5F6F8A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Divider(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: Color(0xFFFF7A00),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.get('news_summary_title', lang),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF7A00),
                                ),
                              ),
                              if (_isLoadingSummary) ...[
                                const Spacer(),
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF7A00),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            displaySummary,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.2,
                              height: 1.55,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1E5BC6),
                                    Color(0xFF0A2A66),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0A2A66).withAlpha(80),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _openNewsDetail,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  AppStrings.get('news_read_more', lang),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

