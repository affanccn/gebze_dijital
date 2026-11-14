import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/emunicipality_provider.dart';
import '../models/emunicipality_model.dart';
import '../../../core/localization/app_strings.dart';

class EBelediyeScreen extends ConsumerStatefulWidget {
  const EBelediyeScreen({super.key});

  @override
  ConsumerState<EBelediyeScreen> createState() => _EBelediyeScreenState();
}

class _EBelediyeScreenState extends ConsumerState<EBelediyeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sayfa açılamadı: $url'),
            backgroundColor: const Color(0xFFE5231B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: const Color(0xFFE5231B),
          ),
        );
      }
    }
  }

  void _onStartService(EBelediyeService service, String lang) {
    if (service.hasModal && service.modalSteps.isNotEmpty) {
      _showModalStepsBottomSheet(service, lang);
    } else {
      _showRedirectConfirmationDialog(service, lang);
    }
  }

  void _showRedirectConfirmationDialog(EBelediyeService service, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5BC6).withAlpha(isDark ? 50 : 20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1E5BC6)
                          .withAlpha(isDark ? 90 : 50),
                    ),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF0A2A66),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0A1F44),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.get('official_portal_sub', lang),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF1E5BC6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFF1E5BC6).withAlpha(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF0A2A66),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.get('id_verify_info', lang),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF0A2A66),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description.isNotEmpty
                        ? service.description
                        : AppStrings.get('ebelediye_redirect_fallback', lang),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF5F6F8A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.get('security_note', lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF0A2A66),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppStrings.get('dismiss', lang),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF5F6F8A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _launchExternalUrl(service.url);
                    },
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      AppStrings.get('btn_start_service', lang),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5BC6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showModalStepsBottomSheet(EBelediyeService service, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalStepWizard(
        service: service,
        lang: lang,
        onSelectUrl: (url) {
          Navigator.of(ctx).pop();
          _launchExternalUrl(url);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final categoriesAsync = ref.watch(eBelediyeCategoriesProvider);
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
            _buildHeader(context, lang, isDark),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) => _buildContent(categories, lang, isDark),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF1E5BC6),
                  ),
                ),
                error: (err, _) =>
                    _buildContent(kFallbackEBelediyeCategories, lang, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String lang, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5BC6), Color(0xFF0A2A66)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330A2A66),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('ebelediye_screen_title', lang),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          AppStrings.get('ebelediye_screen_sub', lang),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark
                      ? Border.all(color: const Color(0xFF334155))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13.5,
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: AppStrings.get(
                      'ebelediye_search_hint_full',
                      lang,
                    ),
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF1E5BC6),
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: isDark ? Colors.white70 : Colors.grey,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<EBelediyeCategory> allCategories,
    String lang,
    bool isDark,
  ) {
    final filteredCategories = <EBelediyeCategory>[];

    for (final cat in allCategories) {
      if (_selectedCategoryId != null && cat.id != _selectedCategoryId) {
        continue;
      }

      if (_searchQuery.isEmpty) {
        filteredCategories.add(cat);
      } else {
        final matchedServices = cat.services.where((s) {
          return s.name.toLowerCase().contains(_searchQuery) ||
              s.description.toLowerCase().contains(_searchQuery);
        }).toList();

        if (matchedServices.isNotEmpty ||
            cat.name.toLowerCase().contains(_searchQuery)) {
          filteredCategories.add(
            EBelediyeCategory(
              id: cat.id,
              name: cat.name,
              icon: cat.icon,
              services: matchedServices.isNotEmpty
                  ? matchedServices
                  : cat.services,
            ),
          );
        }
      }
    }

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _buildInfoBanner(lang, isDark),
        const SizedBox(height: 16),

        _buildCategoryChips(allCategories, lang, isDark),
        const SizedBox(height: 18),

        if (filteredCategories.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 54,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.get('ebelediye_empty_search', lang),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          for (final cat in filteredCategories) ...[
            _buildCategorySection(cat, lang, isDark),
            const SizedBox(height: 24),
          ],
      ],
    );
  }

  Widget _buildInfoBanner(String lang, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(40)
                : const Color(0xFF0A2A66).withAlpha(15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFF1E5BC6).withAlpha(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E5BC6).withAlpha(isDark ? 50 : 25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E5BC6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('ebelediye_guide_title', lang),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.get('ebelediye_guide_desc', lang),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF5F6F8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(
    List<EBelediyeCategory> allCategories,
    String lang,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            label: AppStrings.get('filter_all', lang),
            isSelected: _selectedCategoryId == null,
            isDark: isDark,
            onTap: () => setState(() => _selectedCategoryId = null),
          ),
          for (final cat in allCategories) ...[
            const SizedBox(width: 8),
            _buildFilterChip(
              label: cat.name,
              isSelected: _selectedCategoryId == cat.id,
              isDark: isDark,
              onTap: () => setState(() {
                _selectedCategoryId = _selectedCategoryId == cat.id
                    ? null
                    : cat.id;
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF0A2A66))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF0A2A66))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0A2A66).withAlpha(35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF0A1F44)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    EBelediyeCategory cat,
    String lang,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0A1F44),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 52,
              height: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
            final itemWidth =
                (constraints.maxWidth - ((crossAxisCount - 1) * 12)) /
                crossAxisCount;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final service in cat.services)
                  SizedBox(
                    width: itemWidth,
                    child: _buildServiceCard(service, lang, isDark),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(EBelediyeService service, String lang, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(40)
                : const Color(0xFF0A2A66).withAlpha(14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0288D1).withAlpha(160),
                      width: 1.6,
                    ),
                    color: const Color(0xFF0288D1).withAlpha(isDark ? 40 : 18),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF0288D1),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  service.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                    height: 1.25,
                  ),
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    service.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onStartService(service, lang),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.get('btn_start_service', lang),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF0288D1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0288D1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalStepWizard extends StatefulWidget {
  final EBelediyeService service;
  final String lang;
  final ValueChanged<String> onSelectUrl;

  const _ModalStepWizard({
    required this.service,
    required this.lang,
    required this.onSelectUrl,
  });

  @override
  State<_ModalStepWizard> createState() => _ModalStepWizardState();
}

class _ModalStepWizardState extends State<_ModalStepWizard> {
  late String _currentStepId;
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _currentStepId = widget.service.modalSteps.isNotEmpty
        ? widget.service.modalSteps.first.id
        : 'step1';
  }

  EBelediyeModalStep? get _currentStep {
    for (final step in widget.service.modalSteps) {
      if (step.id == _currentStepId) return step;
    }
    return widget.service.modalSteps.isNotEmpty
        ? widget.service.modalSteps.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = _currentStep;
    if (step == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              if (_history.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentStepId = _history.removeLast();
                    });
                  },
                ),
              Expanded(
                child: Text(
                  step.title.isNotEmpty ? step.title : widget.service.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('select_action_type_sub', widget.lang),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5F6F8A),
            ),
          ),
          const SizedBox(height: 16),

          for (final opt in step.options) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFF1E5BC6).withAlpha(30),
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  opt.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF1E5BC6),
                ),
                onTap: () {
                  if (opt.nextStep.isNotEmpty) {
                    setState(() {
                      _history.add(_currentStepId);
                      _currentStepId = opt.nextStep;
                    });
                  } else if (opt.url.isNotEmpty) {
                    widget.onSelectUrl(opt.url);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
