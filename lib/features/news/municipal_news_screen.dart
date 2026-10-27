import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/municipal_news_list.dart';
import '../../../core/localization/app_strings.dart';

class MunicipalNewsScreen extends ConsumerWidget {
  const MunicipalNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF1F5FD),
        body: Column(
          children: [
            _buildHeader(context, lang),
            const Expanded(child: MunicipalNewsList(itemLimit: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang) {
    return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      AppStrings.get('municipal_news_title', lang),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.newspaper_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 2),
                child: Text(
                  AppStrings.get('municipal_news_sub', lang),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
