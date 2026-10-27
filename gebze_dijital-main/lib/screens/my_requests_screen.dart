import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import 'report_common.dart';

/// Profil > Aktiviteler > Taleplerim / Şikayetlerim
/// Dosya yolu: lib/screens/my_requests_screen.dart
///
/// - [MyRequestsScreen]: tam ekran sayfa (AppBar'lı).
/// - [MyRequestsList]: profildeki Aktiviteler sheet'ine gömülebilen liste.
class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: RC.bg,
      appBar: AppBar(
        backgroundColor: RC.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          rt(lang, 'my_title'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: const MyRequestsList(),
    );
  }
}

class MyRequestsList extends ConsumerStatefulWidget {
  const MyRequestsList({super.key});

  @override
  ConsumerState<MyRequestsList> createState() => _MyRequestsListState();
}

class _MyRequestsListState extends ConsumerState<MyRequestsList> {
  String _filter = 'all'; // all | active | done

  bool _matches(String statusKey) {
    switch (_filter) {
      case 'active':
        return statusKey == 'pending' ||
            statusKey == 'reviewing' ||
            statusKey == 'in_progress';
      case 'done':
        return statusKey == 'resolved' || statusKey == 'rejected';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final async = ref.watch(myReportsProvider);

    return Column(
      children: [
        _filters(lang),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Empty(
              icon: Icons.error_outline_rounded,
              title: '${rt(lang, 'error')}: $e',
            ),
            data: (items) {
              final filtered = items
                  .where((d) => _matches(reportStatusKey(d['status'])))
                  .toList();
              if (filtered.isEmpty) {
                return _Empty(
                  icon: Icons.assignment_outlined,
                  title: rt(lang, 'empty'),
                  subtitle: rt(lang, 'empty_hint'),
                );
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _RequestCard(
                  data: filtered[i],
                  lang: lang,
                  onTap: () => _openDetail(filtered[i], lang),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filters(String lang) {
    final items = <String, String>{
      'all': rt(lang, 'filter_all'),
      'active': rt(lang, 'filter_active'),
      'done': rt(lang, 'filter_done'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final e in items.entries) ...[
            ChoiceChip(
              label: Text(e.value),
              selected: _filter == e.key,
              showCheckmark: false,
              selectedColor: RC.navy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _filter == e.key ? Colors.white : RC.textDark,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _filter == e.key ? RC.navy : RC.border),
              ),
              onSelected: (_) => setState(() => _filter = e.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  void _openDetail(Map<String, dynamic> data, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(data: data, lang: lang),
    );
  }
}

String _categoryLabel(Map<String, dynamic> data, String lang) {
  final key = data['categoryKey']?.toString();
  if (key != null && key.isNotEmpty) return rt(lang, 'cat_$key');
  final raw = (data['category'] ?? '').toString();
  return raw.isEmpty ? rt(lang, 'cat_other') : raw;
}

// ───────────────────────── Kart ─────────────────────────

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final VoidCallback onTap;
  const _RequestCard({
    required this.data,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusKey = reportStatusKey(data['status']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RC.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: reportPhoto(data, width: 70, height: 70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _categoryLabel(data, lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: RC.textDark,
                          ),
                        ),
                      ),
                      _StatusChip(statusKey: statusKey, lang: lang),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${data['ticketNo'] ?? ''}  •  ${data['neighborhood'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: RC.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (data['description'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: RC.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fmtDateTime(data['createdAt']),
                    style: const TextStyle(fontSize: 11, color: RC.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String statusKey;
  final String lang;
  const _StatusChip({required this.statusKey, required this.lang});

  @override
  Widget build(BuildContext context) {
    final color = reportStatusColor(statusKey);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reportStatusIcon(statusKey), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            rt(lang, 'status_$statusKey'),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Detay ─────────────────────────

class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  const _DetailSheet({required this.data, required this.lang});

  List<Map<String, dynamic>> _history() {
    final raw = data['statusHistory'];
    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }
    if (list.isEmpty) {
      list.add({'status': data['status'], 'at': data['createdAt']});
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final statusKey = reportStatusKey(data['status']);
    final hasPhoto =
        (data['photoUrl'] ?? '').toString().isNotEmpty ||
        (data['photoBase64'] ?? '').toString().isNotEmpty;
    final history = _history().reversed.toList(); // en yeni üstte
    final note = (data['adminNote'] ?? data['response'] ?? '').toString();
    final address = (data['address'] ?? '').toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _categoryLabel(data, lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: RC.navy,
                    ),
                  ),
                ),
                _StatusChip(statusKey: statusKey, lang: lang),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${rt(lang, 'ticket')}: ${data['ticketNo'] ?? '-'}',
              style: const TextStyle(
                fontSize: 12.5,
                color: RC.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: reportPhoto(data, height: 200, width: double.infinity),
              ),
            const SizedBox(height: 12),
            _kv(
              Icons.location_on_rounded,
              '${data['neighborhood'] ?? '-'}${address.isNotEmpty ? ' • $address' : ''}',
            ),
            _kv(
              Icons.schedule_rounded,
              '${rt(lang, 'created')}: ${fmtDateTime(data['createdAt'])}',
            ),
            const SizedBox(height: 8),
            Text(
              (data['description'] ?? '').toString(),
              style: const TextStyle(
                fontSize: 13.5,
                color: RC.textDark,
                height: 1.4,
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RC.green.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rt(lang, 'admin_note'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: RC.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(note, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              rt(lang, 'history'),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: RC.textDark,
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < history.length; i++)
              _TimelineTile(
                statusKey: reportStatusKey(history[i]['status']),
                at: history[i]['at'],
                lang: lang,
                isFirst: i == 0,
                isLast: i == history.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: RC.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: RC.textMuted),
          ),
        ),
      ],
    ),
  );
}

class _TimelineTile extends StatelessWidget {
  final String statusKey;
  final dynamic at;
  final String lang;
  final bool isFirst;
  final bool isLast;
  const _TimelineTile({
    required this.statusKey,
    required this.at,
    required this.lang,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = reportStatusColor(statusKey);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  reportStatusIcon(statusKey),
                  size: 20,
                  color: isFirst ? color : RC.textMuted,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: RC.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rt(lang, 'status_$statusKey'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isFirst ? color : RC.textDark,
                    ),
                  ),
                  Text(
                    fmtDateTime(at),
                    style: const TextStyle(fontSize: 11.5, color: RC.textMuted),
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

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _Empty({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: RC.textMuted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: RC.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: RC.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
