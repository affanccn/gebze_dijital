import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/map_launcher.dart';
import '../application/parking_provider.dart';
import '../domain/parking_lot.dart';

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFE5231B);
  static const success = Color(0xFF1E9E54);
  static const border = Color(0xFFE3EAF6);
  static const navyGradient = [Color(0xFF1E5BC6), Color(0xFF0A2A66)];
}

Color _statusColor(ParkingStatus s) => switch (s) {
  ParkingStatus.musait => _C.success,
  ParkingStatus.yogun => _C.orange,
  ParkingStatus.dolu => _C.danger,
};

String _statusText(ParkingStatus s) => switch (s) {
  ParkingStatus.musait => 'Müsait',
  ParkingStatus.yogun => 'Yoğun',
  ParkingStatus.dolu => 'Dolu',
};

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class ParkingScreen extends ConsumerWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parkingSnapshotProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_parking_rounded,
                        color: _C.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Otopark bilgisi yüklenemedi.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : _C.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: _C.navy),
                        onPressed: () => ref.refresh(parkingSnapshotProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (snap) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SummaryCard(snap: snap),
                  const SizedBox(height: 14),
                  for (final item in snap.items) ...[
                    _LotCard(item: item),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.navy, _C.navyDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'OTOPARK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_parking_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Gebze genelindeki otoparkların tahmini doluluk durumu ve yol tarifi.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .75),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
  color: isDark ? const Color(0xFF1E293B) : Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: isDark ? const Color(0xFF334155) : _C.border),
  boxShadow: isDark
      ? null
      : [
          BoxShadow(
            color: _C.navy.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
);

class _SummaryCard extends StatelessWidget {
  final ParkingSnapshot snap;
  const _SummaryCard({required this.snap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Gebze Genel Doluluk',
                  style: TextStyle(
                    color: isDark ? Colors.white : _C.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '%${snap.totalPercent}',
                style: TextStyle(
                  color: isDark ? const Color(0xFF60A5FA) : _C.navy,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(
            value: snap.totalPercent / 100,
            color: isDark ? const Color(0xFF3B82F6) : _C.navy,
            height: 10,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'Toplam Kapasite', value: '${snap.totalCapacity}'),
              _Stat(label: 'Dolu', value: '${snap.totalOccupied}'),
              _Stat(
                label: 'Boş',
                value: '${snap.totalFree}',
                color: _C.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : _C.border,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: _C.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tahmini veridir • Son güncelleme ${_hm(snap.updatedAt)} → Sonraki ${_hm(snap.nextUpdateAt)}',
                  style: const TextStyle(color: _C.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _C.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white : _C.textDark),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const _Bar({required this.value, required this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: isDark
            ? const Color(0xFF334155)
            : const Color(0xFFE6ECF7),
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  final ParkingOccupancy item;
  const _LotCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE8F0FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.local_parking_rounded,
                  color: isDark ? const Color(0xFF93C5FD) : _C.navy,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.lot.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : _C.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.lot.code,
                      style: const TextStyle(
                        color: _C.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusText(item.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : _C.border,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Doluluk Oranı',
                style: TextStyle(color: _C.textMuted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '%${item.percent} Dolu',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Bar(value: item.ratio, color: color),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Box(
                  label: 'Boş Yer Sayısı',
                  value: '${item.free}',
                  color: color,
                  tint: isDark
                      ? const Color(0xFF0F2D20)
                      : color.withValues(alpha: .08),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Box(
                  label: 'Toplam Kapasite',
                  value: '${item.lot.capacity}',
                  tint: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF4F7FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 15,
                color: _C.textMuted,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '7/24 Güvenli Otopark',
                  style: TextStyle(color: _C.textMuted, fontSize: 12),
                ),
              ),
              _DirectionsButton(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final Color tint;
  const _Box({
    required this.label,
    required this.value,
    required this.tint,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _C.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white : _C.textDark),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  final ParkingOccupancy item;
  const _DirectionsButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final ok = await openDirections(lat: item.lot.lat, lng: item.lot.lng);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Harita uygulaması açılamadı.')),
            );
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _C.navyGradient,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Yol Tarifi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
