import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pharmacy_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsyncValue = ref.watch(pharmacyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nöbetçi Eczaneler'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF1F5FD),
      body: pharmaciesAsyncValue.when(
        data: (pharmacies) {
          if (pharmacies.isEmpty) {
            return const Center(child: Text('Bugün için nöbetçi eczane bulunamadı.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = pharmacies[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_pharmacy, color: Color(0xFFE5231B), size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pharmacy.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                          const Icon(Icons.location_on, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pharmacy.address,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            pharmacy.phone,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (pharmacy.phone.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                final uri = Uri.parse('tel:${pharmacy.phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
                                launchUrl(uri);
                              },
                              icon: const Icon(Icons.call),
                              label: const Text('Ara'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0A2A66),
                              ),
                            ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              final query = pharmacy.loc.isNotEmpty 
                                ? pharmacy.loc 
                                : '${pharmacy.name} Eczanesi ${pharmacy.district}';
                              final uri = Uri.parse('https://maps.google.com/?q=$query');
                              launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Yol Tarifi'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE5231B),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Bir hata oluştu: $error')),
      ),
    );
  }
}
