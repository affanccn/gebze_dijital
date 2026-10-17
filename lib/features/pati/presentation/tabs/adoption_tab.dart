import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/pati_data_provider.dart';
import '../../models/pet_adoption.dart';
import '../../../../core/localization/app_strings.dart';

class AdoptionTab extends ConsumerWidget {
  const AdoptionTab({super.key});

  static const String _centerPhoneClean = '02626420430';

  Future<void> _callCenter(
    BuildContext context,
    String phone,
    String lang,
  ) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        final msg = AppStrings.get(
          'call_failed_toast',
          lang,
        ).replaceAll('{0}', phone);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final petState = ref.watch(petAdoptionsStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // 1. SAHİPLENDİRME SÜRECİ NASIL İŞLER? BANNER & AŞAMALAR
        _buildProcessCard(context, lang),
        const SizedBox(height: 20),

        // 2. YUVA ARAYAN CAN DOSTLARIMIZ BAŞLIĞI
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFFF7A00),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('adoption_header_title', lang),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0A1F44),
                    ),
                  ),
                  Text(
                    AppStrings.get('adoption_header_sub', lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF5F6F8A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. HAYVAN LİSTESİ (FIRESTORE STREAM & ADMIN PANELİYLE ENTEGRE)
        petState.when(
          data: (pets) {
            if (pets.isEmpty) {
              return _buildEmptyState(context, lang);
            }
            return Column(
              children: pets
                  .map((pet) => _buildPetCard(context, pet, lang))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildPetErrorState(ref, lang),
        ),
      ],
    );
  }

  Widget _buildProcessCard(BuildContext context, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = [
      {
        'step': '1',
        'title': AppStrings.get('step1_title', lang),
        'desc': AppStrings.get('step1_desc', lang),
      },
      {
        'step': '2',
        'title': AppStrings.get('step2_title', lang),
        'desc': AppStrings.get('step2_desc', lang),
      },
      {
        'step': '3',
        'title': AppStrings.get('step3_title', lang),
        'desc': AppStrings.get('step3_desc', lang),
      },
      {
        'step': '4',
        'title': AppStrings.get('step4_title', lang),
        'desc': AppStrings.get('step4_desc', lang),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0A2A66).withAlpha(18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.rule_folder_rounded,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.get('adoption_process_title', lang),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFA11F), Color(0xFFFF6A00)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      s['step']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0A1F44),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['desc']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF5F6F8A),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5FD),
              borderRadius: BorderRadius.circular(10),
              border: isDark
                  ? Border.all(color: const Color(0xFF334155))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF0A2A66),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.get('free_adoption_badge', lang),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF0A2A66),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, PetAdoption pet, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final speciesText = pet.species == 'Köpek'
        ? AppStrings.get('pet_dog', lang)
        : pet.species == 'Kedi'
        ? AppStrings.get('pet_cat', lang)
        : pet.species;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0A2A66).withAlpha(16),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resim ve Tür Rozeti
          Stack(
            children: [
              pet.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: pet.imageUrl,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 190,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildImagePlaceholder(pet),
                    )
                  : _buildImagePlaceholder(pet),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: pet.species == 'Köpek'
                        ? const Color(0xFF0A2A66)
                        : const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pet.species == 'Köpek'
                            ? Icons.pets_rounded
                            : Icons.cruelty_free_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$speciesText • ${pet.breed}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pet.gender} • ${pet.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pet.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0A1F44),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A2B)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.get('looking_for_home', lang),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF2E7D32),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (pet.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    pet.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF4A5568),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF1E5BC6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pet.healthStatus,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF5F6F8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF334155) : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('adopt_contact_label', lang),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF5F6F8A),
                            ),
                          ),
                          Text(
                            AppStrings.get('adopt_center_name', lang),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0A1F44),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _callCenter(
                        context,
                        pet.centerPhone.isNotEmpty
                            ? pet.centerPhone
                            : _centerPhoneClean,
                        lang,
                      ),
                      icon: const Icon(Icons.call_rounded, size: 17),
                      label: Text(AppStrings.get('btn_call', lang)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(PetAdoption pet) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2A66), Color(0xFF1E5BC6)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pet.species == 'Köpek'
                  ? Icons.pets_rounded
                  : Icons.cruelty_free_rounded,
              size: 54,
              color: Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              pet.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.pets_rounded,
            size: 48,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5F6F8A),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('no_pets_found', lang),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0A1F44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetErrorState(WidgetRef ref, String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: () => ref.refresh(petAdoptionsStreamProvider),
          child: Text(AppStrings.get('btn_retry', lang)),
        ),
      ),
    );
  }
}
