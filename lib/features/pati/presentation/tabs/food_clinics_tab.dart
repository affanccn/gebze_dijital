import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/pati_data_provider.dart';
import '../../models/feeding_point.dart';

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
    return points.where((fp) => fp.neighborhood == _selectedNeighborhood).toList();
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
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final feedingPointsAsync = ref.watch(feedingPointsStreamProvider);
    final vetClinicsAsync = ref.watch(vetClinicsStreamProvider);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // 1. MAMA VE SU ODAKLARI AĞI BAŞLIK & AÇIKLAMA KARTI
        _buildFeedingPointsHeader(context),
        const SizedBox(height: 14),

        // Besleme Noktaları (Canlı Firestore Stream / Admin Panel Senkronize)
        feedingPointsAsync.when(
          data: (points) {
            final neighborhoods = _getNeighborhoods(points);
            final filtered = _filterPoints(points);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNeighborhoodChips(neighborhoods),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  _buildEmptySection('Bu mahallede kayıtlı besleme odağı bulunamadı.')
                else
                  ...filtered.map((fp) => _buildFeedingPointCard(fp)),
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
            children: kGebzeFeedingPoints.map((fp) => _buildFeedingPointCard(fp)).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // 2. ÖZEL NÖBETÇİ VETERİNER KLİNİKLERİ BÖLÜMÜ (Canlı Firestore Stream / Admin Senkronize)
        _buildVetClinicsHeader(context),
        const SizedBox(height: 14),

        vetClinicsAsync.when(
          data: (clinics) {
            if (clinics.isEmpty) {
              return _buildEmptySection('Kayıtlı nöbetçi veteriner kliniği bulunamadı.');
            }
            return Column(
              children: clinics.map((c) => _buildVetClinicCard(c)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Column(
            children: kGebzeDutyVetClinics.map((c) => _buildVetClinicCard(c)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6F8A))),
    );
  }

  Widget _buildFeedingPointsHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF1E5BC6), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gebze Mama & Su Odakları Ağı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    Text(
                      'Belediyemizin mahalle odaklı besleme ve su noktaları',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5F6F8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Gebze genelinde sokak hayvanlarımızın sağlıklı beslenmesi ve taze suya erişimi için kurulan istasyonlar periyodik olarak temizlenmekte ve mama takviyesi yapılmaktadır.',
            style: TextStyle(fontSize: 13, color: Color(0xFF334A6E), height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborhoodChips(List<String> neighborhoods) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: neighborhoods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final n = neighborhoods[index];
          final isSelected = n == _selectedNeighborhood;
          return ChoiceChip(
            label: Text(
              n,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0A2A66),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFF0A2A66),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? const Color(0xFF0A2A66) : const Color(0xFF0A2A66).withAlpha(30),
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

  Widget _buildFeedingPointCard(FeedingPoint fp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
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
                child: const Icon(Icons.room_service_rounded, color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fp.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fp.neighborhood} • ${fp.type}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E5BC6), fontWeight: FontWeight.w600),
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
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF5F6F8A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fp.address,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A5568)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFFFF7A00)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Neler Var: ${fp.equipment}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0A1F44), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewOnMap(fp.latitude, fp.longitude, fp.title),
                  icon: const Icon(Icons.map_rounded, size: 17),
                  label: const Text('Haritada Gör'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A2A66),
                    side: BorderSide(color: const Color(0xFF0A2A66).withAlpha(50)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(fp.latitude, fp.longitude, fp.title),
                  icon: const Icon(Icons.directions_rounded, size: 17),
                  label: const Text('Yol Tarifi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2A66),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVetClinicsHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A2A66),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital_rounded, color: Color(0xFFFF7A00), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sahipli Evcil Hayvanlar İçin Nöbetçi Klinikler',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Evcil can dostunuzun acil sağlık durumlarında Gebze genelinde 7/24 veya gece saatlerinde hizmet veren özel nöbetçi veteriner klinikleri listesi ve iletişim bilgileri.',
            style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildVetClinicCard(DutyVetClinic clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
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
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_information_rounded, color: Color(0xFFE5231B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinic.emergencyHours,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE5231B),
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
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF5F6F8A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  clinic.address,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A5568)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF5F6F8A)),
              const SizedBox(width: 6),
              Text(
                clinic.phone,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0A1F44)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(clinic.phone),
                  icon: const Icon(Icons.call_rounded, size: 17),
                  label: const Text('Telefon Et'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A2A66),
                    side: BorderSide(color: const Color(0xFF0A2A66).withAlpha(50)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(clinic.latitude, clinic.longitude, clinic.name),
                  icon: const Icon(Icons.directions_rounded, size: 17),
                  label: const Text('Yol Tarifi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5231B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
