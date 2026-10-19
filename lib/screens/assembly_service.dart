import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Dosya yolu: lib/screens/assembly_service.dart
///
/// Toplanma alanlarını doğrudan Gebze Kent Rehberi'nden çeker:
///   https://kentrehberi.gebze.bel.tr/ToplanmaAlanlari/GetCardsPartial
///
/// Akış: ağdan çek → parse et → önbelleğe yaz. Ağ yoksa son başarılı
/// önbellek kullanılır (afet anında internet olmayabilir).
///
/// pubspec.yaml'a eklenecek paketler:
///   http, html, shared_preferences

const String kAssemblyUrl =
    'https://kentrehberi.gebze.bel.tr/ToplanmaAlanlari/GetCardsPartial';

const String _kCacheKey = 'assembly_areas_cache_v1';
const String _kCacheTimeKey = 'assembly_areas_cache_time_v1';

/// Konum izni yoksa mesafe hesabı için kullanılan referans nokta (Gebze merkez).
const double kGebzeCenterLat = 40.8028;
const double kGebzeCenterLng = 29.4307;

/// Toplanma alanı türü. Etiketler ekranda dile göre çevrilir.
enum AreaKind { park, market, picnic, school, hospital, forest, municipal, sport, other }

/// Toplanma Alanı Veri Modeli
class AssemblyArea {
  final String id;
  final String name;
  final String neighborhood;
  final String street; // boş olabilir
  final double latitude;
  final double longitude;
  final int? areaM2;
  final bool hasElectricity;
  final bool hasWater;
  final bool hasWc;
  final AreaKind kind;

  const AssemblyArea({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.street,
    required this.latitude,
    required this.longitude,
    required this.areaM2,
    required this.hasElectricity,
    required this.hasWater,
    required this.hasWc,
    required this.kind,
  });

  /// Kişi başı ~3,5 m² varsayımıyla TAHMİNİ kapasite (resmi veri değildir).
  int? get estimatedCapacity => areaM2 == null ? null : (areaM2! / 3.5).floor();

  /// "8.735 m²"
  String get areaText => areaM2 == null ? '' : '${_thousands(areaM2!)} m²';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'neighborhood': neighborhood,
    'street': street,
    'lat': latitude,
    'lng': longitude,
    'area': areaM2,
    'e': hasElectricity,
    'w': hasWater,
    'wc': hasWc,
    'kind': kind.name,
  };

  factory AssemblyArea.fromJson(Map<String, dynamic> j) => AssemblyArea(
    id: j['id'] as String,
    name: j['name'] as String,
    neighborhood: j['neighborhood'] as String,
    street: j['street'] as String,
    latitude: (j['lat'] as num).toDouble(),
    longitude: (j['lng'] as num).toDouble(),
    areaM2: j['area'] as int?,
    hasElectricity: j['e'] as bool,
    hasWater: j['w'] as bool,
    hasWc: j['wc'] as bool,
    kind: AreaKind.values.firstWhere(
      (k) => k.name == j['kind'],
      orElse: () => AreaKind.other,
    ),
  );
}

class AssemblyResult {
  final List<AssemblyArea> areas;
  final bool fromCache;
  final DateTime? cachedAt;
  const AssemblyResult(this.areas, {this.fromCache = false, this.cachedAt});
}

final assemblyAreasProvider = FutureProvider<AssemblyResult>(
  (ref) => AssemblyService.load(),
);

class AssemblyService {
  static Future<AssemblyResult> load({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await http
          .get(
            Uri.parse(kAssemblyUrl),
            headers: const {
              'Accept': 'text/html, */*; q=0.01',
              'X-Requested-With': 'XMLHttpRequest',
              'User-Agent': 'GebzeDijital/1.0 (Flutter)',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final areas = parse(utf8.decode(res.bodyBytes));
      if (areas.isEmpty) throw Exception('Boş yanıt');

      await prefs.setString(
        _kCacheKey,
        jsonEncode(areas.map((a) => a.toJson()).toList()),
      );
      await prefs.setString(_kCacheTimeKey, DateTime.now().toIso8601String());
      return AssemblyResult(areas);
    } catch (_) {
      final raw = prefs.getString(_kCacheKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => AssemblyArea.fromJson(e as Map<String, dynamic>))
            .toList();
        return AssemblyResult(
          list,
          fromCache: true,
          cachedAt: DateTime.tryParse(prefs.getString(_kCacheTimeKey) ?? ''),
        );
      }
      rethrow;
    }
  }

  // ───────────────────────── Parse ─────────────────────────

  static final _showOnMap = RegExp(r'ShowOnMap\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)');
  static final _destination = RegExp(r'destination=([-\d.]+),([-\d.]+)');

  static List<AssemblyArea> parse(String htmlText) {
    final doc = html_parser.parse(htmlText);
    final out = <AssemblyArea>[];

    for (final card in doc.querySelectorAll('div.card-item')) {
      final rawName = card.querySelector('h5.card-title')?.text ?? '';
      final name = _cleanName(rawName);
      if (name.isEmpty) continue;

      final coords = _coords(card);
      if (coords == null) continue; // geçersiz konumu listeye alma

      final fields = <String, String>{};
      for (final row in card.querySelectorAll('div.mb-2')) {
        final key = row.querySelector('span.fw-bold')?.text.trim();
        final val = row.querySelector('span.text-end')?.text.trim();
        if (key != null && val != null) {
          fields[key.replaceAll(':', '')] = val;
        }
      }

      final infra = <String, bool>{};
      for (final sp in card.querySelectorAll('span.d-flex.align-items-center.gap-1')) {
        final label = sp.querySelector('small')?.text.trim().replaceAll(':', '');
        final badge = sp.querySelector('.badge')?.text.trim();
        if (label != null && badge != null) infra[label] = badge == 'Var';
      }

      out.add(
        AssemblyArea(
          id: card.attributes['data-guid'] ?? name,
          name: name,
          neighborhood: _cleanNeighborhood(fields['Mahalle'] ?? ''),
          street: _cleanStreet(fields['Cadde/Sokak'] ?? ''),
          latitude: coords.$1,
          longitude: coords.$2,
          areaM2: _parseArea(fields['Alan'] ?? ''),
          hasElectricity: infra['Elektrik'] ?? false,
          hasWater: infra['Su'] ?? false,
          hasWc: infra['WC'] ?? false,
          kind: _kindOf(name),
        ),
      );
    }
    return out;
  }

  /// (lat, lng) döner. Sitede ShowOnMap(BOYLAM, ENLEM) sırası TERS verilir;
  /// Google linklerindeki destination=ENLEM,BOYLAM güvenilir kaynaktır.
  static (double, double)? _coords(Element card) {
    final raw = card.outerHtml;
    double? lat, lng;

    final d = _destination.firstMatch(raw);
    if (d != null) {
      lat = double.tryParse(d.group(1)!);
      lng = double.tryParse(d.group(2)!);
    }
    if (lat == null || lng == null) {
      final m = _showOnMap.firstMatch(raw);
      if (m != null) {
        lng = double.tryParse(m.group(1)!);
        lat = double.tryParse(m.group(2)!);
      }
    }
    if (lat == null || lng == null) return null;

    // Gebze ilçesi sınırları (geniş kutu): yanlış/ters girilmiş koordinatı ele.
    final ok = lat > 40.65 && lat < 41.10 && lng > 29.20 && lng < 29.85;
    return ok ? (lat, lng) : null;
  }

  // ───────────────────────── Temizlik ─────────────────────────

  static String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  static const _keepUpper = {'İO', 'KBB', 'İSU', 'FSM'};

  static String _trLower(String s) =>
      s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  static String _trUpper(String s) =>
      s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  /// "ADEMYAVUZ PAZAR  ALANI" → "Ademyavuz Pazar Alanı"
  static String _cleanName(String raw) {
    final s = _collapse(raw);
    if (s == _trUpper(s)) {
      // Tamamı büyük harf → Türkçe başlık biçimi
      return s.replaceAllMapped(RegExp(r"[^\s.\-()/]+"), (m) {
        final w = m.group(0)!;
        if (_keepUpper.contains(w)) return w;
        return _trUpper(w.substring(0, 1)) + _trLower(w.substring(1));
      });
    }
    return s;
  }

  static const _neighborhoodFix = {
    'Sultanorhan': 'Sultan Orhan',
    'Köşklüçeşme': 'Köşklü Çeşme',
  };

  /// "Mudarlı Mah. İç Yolu" → "Mudarlı", "Yağcılar Mah." → "Yağcılar"
  static String _cleanNeighborhood(String raw) {
    var s = _collapse(raw).replaceAll(RegExp(r'\s+Mah(\.|alle|allesi)?.*$'), '');
    return _neighborhoodFix[s] ?? s;
  }

  static String _cleanStreet(String raw) => _collapse(
    raw,
  ).replaceAll('Mhalle', 'Mahalle').replaceAll('İçyolu', 'İç Yolu');

  /// "8735m²" → 8735
  static int? _parseArea(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  static AreaKind _kindOf(String name) {
    final n = _trUpper(name);
    bool has(String k) => n.contains(k);
    if (has('PAZAR')) return AreaKind.market;
    if (has('HASTA') || has('SAĞLIK')) return AreaKind.hospital;
    if (has('MESİRE') || has('PİKNİK') || has('ÇAYIRI') || has('VADİSİ')) {
      return AreaKind.picnic;
    }
    if (has('ORMAN')) return AreaKind.forest;
    if (has('OKUL') || has('LİSE') || has(' İO') || has('MERKEZİ')) {
      return AreaKind.school;
    }
    if (has('SPOR')) return AreaKind.sport;
    if (has('BELEDİYE') || has('MÜDÜRLÜĞ') || has('MEYDAN')) {
      return AreaKind.municipal;
    }
    if (has('PARK')) return AreaKind.park;
    return AreaKind.other;
  }
}

String _thousands(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}