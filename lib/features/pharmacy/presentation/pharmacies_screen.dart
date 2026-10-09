import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pharmacy_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsyncValue = ref.watch(pharmacyProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FD),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: pharmaciesAsyncValue.when(
                data: (pharmacies) {
                  if (pharmacies.isEmpty) {
                    return const Center(child: Text('Bugün için nöbetçi eczane bulunamadı.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: pharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = pharmacies[index];
                      return _buildPharmacyCard(context, pharmacy);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Bir hata oluştu: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5A4F), Color(0xFFE5231B)],
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'NÖBETÇİ ECZANELER',
                      style: TextStyle(
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
                    child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 48, top: 2),
                child: Text(
                  'Gebze genelinde nöbetçi eczane bilgileri ve iletişim.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, dynamic pharmacy) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: const Color(0xFF0A2A66).withAlpha(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFFE5231B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pharmacy.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF5F6F8A), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pharmacy.address,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0A1F44)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_rounded, color: Color(0xFF5F6F8A), size: 18),
                const SizedBox(width: 8),
                Text(
                  pharmacy.phone,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A1F44)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.withAlpha(35)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (pharmacy.phone.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final uri = Uri.parse('tel:${pharmacy.phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
                        launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text('Ara'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0A2A66),
                        side: BorderSide(color: const Color(0xFF0A2A66).withAlpha(50)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final query = pharmacy.loc.isNotEmpty 
                        ? pharmacy.loc 
                        : '${pharmacy.name} Eczanesi ${pharmacy.district}';
                      final uri = Uri.parse('https://maps.google.com/?q=$query');
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Yol Tarifi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5231B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
