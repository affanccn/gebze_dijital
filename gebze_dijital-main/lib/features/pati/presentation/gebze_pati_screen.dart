import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import 'tabs/adoption_tab.dart';
import 'tabs/center_ambulance_tab.dart';
import 'tabs/food_clinics_tab.dart';

class GebzePatiScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const GebzePatiScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<GebzePatiScreen> createState() => _GebzePatiScreenState();
}

class _GebzePatiScreenState extends ConsumerState<GebzePatiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FD),
        body: Column(
          children: [
            _buildHeader(context, lang),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  CenterAmbulanceTab(),
                  AdoptionTab(),
                  FoodClinicsTab(),
                ],
              ),
            ),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('pati_screen_title', lang),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          AppStrings.get('pati_screen_sub', lang),
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
                    child: const Icon(Icons.pets_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // TabBar Bölümü
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF0A2A66),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      height: 52,
                      icon: const Icon(Icons.medical_services_rounded, size: 18),
                      text: AppStrings.get('tab_ambulance', lang),
                    ),
                    Tab(
                      height: 52,
                      icon: const Icon(Icons.favorite_rounded, size: 18),
                      text: AppStrings.get('tab_adoption', lang),
                    ),
                    Tab(
                      height: 52,
                      icon: const Icon(Icons.food_bank_rounded, size: 18),
                      text: AppStrings.get('tab_food_clinics', lang),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
