import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/pati_data_provider.dart';
import '../../models/feeding_point.dart';
import '../../../../core/localization/app_strings.dart';

class FoodClinicsTab extends ConsumerStatefulWidget {
  const FoodClinicsTab({super.key});

  @override
  ConsumerState<FoodClinicsTab> createState() => _FoodClinicsTabState();
}

class _FoodClinicsTabState extends ConsumerState<FoodClinicsTab> {
  String _selectedNeighborhood = 'Tümü';

  List<String> _getNeighborhoods(List<FeedingPoint> points) {
    final list = <String>{'Tümü'};
    for (final fp in points) {
      if (fp.neighborhood.isNotEmpty) {
        list.add(fp.neighborhood);
      }
    }
    return list.toList();
  }

  List<FeedingPoint> _filterPoints(List<FeedingPoint> points) {
    if (_selectedNeighborhood == 'Tümü') {
      return points;
    }
    return points
        .where((fp) => fp.neighborhood == _selectedNeighborhood)
        .toList();
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDirections(double lat, double lng, String label) async {
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng($label)');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _viewOnMap(double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final feedingPointsAsync = ref.watch(feedingPointsStreamProvider);
    final vetClinicsAsync = ref.watch(vetClinicsStreamProvider);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // 1. MAMA VE SU ODAKLARI AĞI BAŞLIK & AÇIKLAMA KARTI
        _buildFeedingPointsHeader(context, lang),
        const SizedBox(height: 14),

        // Besleme Noktaları (Canlı Firestore Stream / Admin Panel Senkronize)
        feedingPointsAsync.when(
          data: (points) {
            final neighborhoods = _getNeighborhoods(points);
            final filtered = _filterPoints(points);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNeighborhoodChips(neighborhoods, lang),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  _buildEmptySection(
                    AppStrings.get('no_feeding_points_in_neighborhood', lang),
                  )
                else
                  ...filtered.map((fp) => _buildFeedingPointCard(fp, lang)),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Column(
            children: kGebzeFeedingPoints
                .map((fp) => _buildFeedingPointCard(fp, lang))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),

        // 2. ÖZEL NÖBETÇİ VETERİNER KLİNİKLERİ BÖLÜMÜ (Canlı Firestore Stream / Admin Senkronize)
        _buildVetClinicsHeader(context, lang),
        const SizedBox(height: 14),

        vetClinicsAsync.when(
          data: (clinics) {
            if (clinics.isEmpty) {
              return _buildEmptySection(
                AppStrings.get('no_duty_clinics', lang),
              );
            }
            return Column(
              children: clinics
                  .map((c) => _buildVetClinicCard(c, lang))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Column(
            children: kGebzeDutyVetClinics
                .map((c) => _buildVetClinicCard(c, lang))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF5F6F8A)),
      ),
    );
  }

  Widget _buildFeedingPointsHeader(BuildContext context, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5BC6).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF1E5BC6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('feeding_network_title', lang),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0A1F44),
                      ),
                    ),
                    Text(
                      AppStrings.get('feeding_network_sub', lang),
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
          const SizedBox(height: 12),
          Text(
            AppStrings.get('feeding_network_desc', lang),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334A6E),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborhoodChips(List<String> neighborhoods, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: neighborhoods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final n = neighborhoods[index];
          final isSelected = n == _selectedNeighborhood;
          final labelText = n == 'Tümü'
              ? AppStrings.get('filter_all', lang)
              : n;

          return ChoiceChip(
            label: Text(
              labelText,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0A2A66)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
            selected: isSelected,
            selectedColor: isDark
                ? const Color(0xFF2563EB)
                : const Color(0xFF0A2A66),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            showCheckmark: false,
            side: BorderSide(
              color: isSelected
                  ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF0A2A66))
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFF0A2A66).withAlpha(30)),
            ),
            onSelected: (val) {
              if (val) {
                setState(() => _selectedNeighborhood = n);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedingPointCard(FeedingPoint fp, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.room_service_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fp.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fp.neighborhood} • ${fp.type}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1E5BC6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF5F6F8A),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fp.address,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF4A5568),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: Color(0xFFFF7A00),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${AppStrings.get('equipment_label', lang)} ${fp.equipment}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : null),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _viewOnMap(fp.latitude, fp.longitude, fp.title),
                  icon: const Icon(Icons.map_rounded, size: 17),
                  label: Text(AppStrings.get('btn_map', lang)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF0A2A66),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF60A5FA).withAlpha(120)
                          : const Color(0xFF0A2A66).withAlpha(50),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openDirections(fp.latitude, fp.longitude, fp.title),
                  icon: const Icon(Icons.directions_rounded, size: 17),
                  label: Text(AppStrings.get('btn_directions', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF0A2A66),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVetClinicsHeader(BuildContext context, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A2A66),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_hospital_rounded,
                color: Color(0xFFFF7A00),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.get('duty_clinics_title', lang),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('duty_clinics_desc', lang),
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVetClinicCard(DutyVetClinic clinic, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A1E24)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_information_rounded,
                  color: Color(0xFFE5231B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinic.emergencyHours,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFFE5231B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF5F6F8A),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  clinic.address,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF4A5568),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.phone_rounded,
                size: 16,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF5F6F8A),
              ),
              const SizedBox(width: 6),
              Text(
                clinic.phone,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0A1F44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : null),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(clinic.phone),
                  icon: const Icon(Icons.call_rounded, size: 17),
                  label: Text(AppStrings.get('btn_call', lang)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF0A2A66),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF60A5FA).withAlpha(120)
                          : const Color(0xFF0A2A66).withAlpha(50),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(
                    clinic.latitude,
                    clinic.longitude,
                    clinic.name,
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 17),
                  label: Text(AppStrings.get('btn_directions', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5231B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
