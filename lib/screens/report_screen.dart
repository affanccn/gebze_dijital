import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../core/localization/app_strings.dart';
import '../features/profile/services/profile_service.dart';
import 'profile_screen.dart';
import 'report_common.dart';

/// Gebze Belediyesi - Çek & Gönder (Bildir)
/// Dosya yolu: lib/screens/report_screen.dart
///
/// Akış: Fotoğraf → Konum → Kategori → Açıklama → Özet ve Gönder
/// Veri: Firestore `reports` koleksiyonu + Storage `reports/{uid}/{id}.jpg`
class ReportScreen extends ConsumerStatefulWidget {
  final bool isGuest;
  const ReportScreen({super.key, this.isGuest = false});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  static const int _lastStep = 4;

  final _picker = ImagePicker();
  final _descCtrl = TextEditingController();

  int _step = 0;
  String? _stepError;

  File? _photo;

  bool _autoLocation = true;
  bool _locating = false;
  Position? _position;
  String? _address;
  String? _neighborhood;
  String? _locationErrorKey;

  String? _category;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Profildeki mahalle varsa konum adımında hazır gelsin.
    final profileHood = ref.read(profileProvider).value?.neighborhood;
    final match = _matchNeighborhood([profileHood]);
    if (match != null) _neighborhood = match;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── Fotoğraf ─────────────────────────

  Future<void> _pickPhoto(ImageSource source, String lang) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (x == null) return;
      setState(() {
        _photo = File(x.path);
        _stepError = null;
      });
    } catch (e) {
      _snack('${rt(lang, 'error')}: $e');
    }
  }

  // ───────────────────────── Konum ─────────────────────────

  String? _matchNeighborhood(Iterable<String?> candidates) {
    for (final c in candidates) {
      if (c == null || c.trim().isEmpty) continue;
      final f = foldTr(c);
      for (final n in kReportNeighborhoods) {
        final fn = foldTr(n);
        if (f == fn || f.contains(fn)) return n;
      }
    }
    return null;
  }

  /// Koordinattan mahalle/adres bulur (OpenStreetMap Nominatim, ek paket yok).
  /// Dönüş: (eşleşen mahalle, kısa adres)
  Future<(String?, String?)> _reverseGeocode(double lat, double lon) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': lat.toString(),
        'lon': lon.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'tr',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'GebzeDijital/1.0');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return (null, null);
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      final a = (json is Map ? json['address'] : null);
      if (a is! Map) return (null, null);

      String? v(String k) => a[k]?.toString();
      final hood = _matchNeighborhood([
        v('suburb'),
        v('neighbourhood'),
        v('quarter'),
        v('village'),
        v('city_district'),
      ]);
      final addr =
          [v('road'), v('suburb') ?? v('neighbourhood'), v('town') ?? v('city')]
              .where((e) => e != null && e.trim().isNotEmpty)
              .map((e) => e!.trim())
              .join(', ');
      return (hood, addr.isEmpty ? null : addr);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _detectLocation() async {
    setState(() {
      _locating = true;
      _locationErrorKey = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('service_off');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      String? hood;
      String? addr;
      try {
        final geo = await _reverseGeocode(pos.latitude, pos.longitude);
        hood = geo.$1;
        addr = geo.$2;
      } catch (_) {
        // Adres çözümlenemese de koordinat yeterli; mahalle elle seçilebilir.
      }

      if (!mounted) return;
      setState(() {
        _position = pos;
        _address = (addr == null || addr.isEmpty) ? null : addr;
        _neighborhood = hood ?? _neighborhood;
        _locating = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _locating = false;
        _locationErrorKey = msg.contains('denied')
            ? 'loc_denied'
            : msg.contains('service_off')
            ? 'loc_service_off'
            : 'loc_failed';
      });
    }
  }

  bool get _hasLocation => _neighborhood != null || _position != null;

  String get _locationText {
    final parts = <String>[];
    if (_neighborhood != null) parts.add('$_neighborhood Mah.');
    if (_address != null && _address!.isNotEmpty && _neighborhood == null) {
      parts.add(_address!);
    }
    if (_position != null) {
      parts.add(
        '(${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)})',
      );
    }
    return parts.join(' ');
  }

  // ───────────────────────── Adım kontrolü ─────────────────────────

  String? _validate(int step, String lang) {
    switch (step) {
      case 0:
        return _photo == null ? rt(lang, 'photo_required') : null;
      case 1:
        return _hasLocation ? null : rt(lang, 'loc_required');
      case 2:
        return _category == null ? rt(lang, 'cat_required') : null;
      case 3:
        return _descCtrl.text.trim().length < 10
            ? rt(lang, 'desc_short')
            : null;
      default:
        return null;
    }
  }

  void _next(String lang) {
    final err = _validate(_step, lang);
    if (err != null) {
      setState(() => _stepError = err);
      HapticFeedback.lightImpact();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _stepError = null;
      _step++;
    });
    // Konum adımına geçince otomatik algıla.
    if (_step == 1 && _autoLocation && _position == null && !_locating) {
      _detectLocation();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    setState(() {
      _stepError = null;
      if (_step > 0) _step--;
    });
  }

  // ───────────────────────── Gönder ─────────────────────────

  Future<void> _submit(String lang) async {
    if (_sending) return;
    for (var i = 0; i < _lastStep; i++) {
      final err = _validate(i, lang);
      if (err != null) {
        setState(() {
          _step = i;
          _stepError = err;
        });
        return;
      }
    }

    setState(() => _sending = true);
    try {
      final uid = await getReportUserId();
      final profile = ref.read(profileProvider).value;
      final ref0 = FirebaseFirestore.instance.collection('reports').doc();
      final ticket =
          'GB-${DateTime.now().year}-${ref0.id.substring(0, 6).toUpperCase()}';

      // Fotoğraf: önce Firebase Storage, olmazsa küçük boyutluysa Firestore'a
      // base64 olarak gömülür (1 MB doküman sınırı nedeniyle ~600 KB üst sınır).
      String? photoUrl;
      String? photoBase64;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        try {
          final sref = FirebaseStorage.instance.ref(
            'reports/$uid/${ref0.id}.jpg',
          );
          await sref
              .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
              .timeout(const Duration(seconds: 20));
          photoUrl = await sref.getDownloadURL().timeout(
            const Duration(seconds: 10),
          );
        } catch (_) {
          if (bytes.length <= 600 * 1024) photoBase64 = base64Encode(bytes);
        }
      }

      final now = Timestamp.now();
      final statusTr = kReportStatusTr['pending']!;
      final reportMap = <String, dynamic>{
        '_id': ref0.id,
        'ticketNo': ticket,
        'userId': uid,
        'isGuest': widget.isGuest,
        if ((profile?.fullName ?? '').isNotEmpty) 'userName': profile!.fullName,
        if ((profile?.phoneNumber ?? '').isNotEmpty)
          'userPhone': profile!.phoneNumber,
        'category': rt('tr', 'cat_$_category'),
        'categoryKey': _category,
        'description': _descCtrl.text.trim(),
        'neighborhood': _neighborhood,
        'address': _address,
        if (_position != null)
          'location': GeoPoint(_position!.latitude, _position!.longitude),
        'locationSource': _position != null && _autoLocation ? 'gps' : 'manual',
        'photoUrl': photoUrl,
        'photoBase64': photoBase64,
        'status': statusTr,
        'statusHistory': [
          {'status': statusTr, 'at': now},
        ],
        'createdAt': now,
        'updatedAt': now,
      };

      // Taleplerim ekranında anında görünmesi için yerel listeye ekle
      localSubmittedReports.insert(0, reportMap);
      ref.invalidate(myReportsProvider);

      try {
        await ref0.set({
          ...reportMap,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Çevrimdışı / misafir modunda yerel kopya yeterlidir
      }

      if (!mounted) return;
      setState(() => _sending = false);
      await _showSuccess(lang, ticket);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack('${rt(lang, 'error')}: $e');
    }
  }

  Future<void> _showSuccess(String lang, String ticket) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final openList = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark
              ? const BorderSide(color: Color(0xFF334155))
              : BorderSide.none,
        ),
        icon: const Icon(Icons.check_circle_rounded, color: RC.green, size: 48),
        title: Text(
          rt(lang, 'sent_title'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : RC.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rt(lang, 'sent_body'),
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : RC.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              ticket,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFF38BDF8) : RC.navy,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              rt(lang, 'sent_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : RC.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              rt(lang, 'btn_ok'),
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: RC.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(rt(lang, 'btn_my_requests')),
          ),
        ],
      ),
    );

    _resetForm();
    if (openList == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(openRequestsOnStart: true),
        ),
      );
    }
  }

  void _resetForm() {
    if (!mounted) return;
    setState(() {
      _step = 0;
      _stepError = null;
      _photo = null;
      _position = null;
      _address = null;
      _neighborhood = null;
      _category = null;
      _locationErrorKey = null;
      _descCtrl.clear();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: RC.navyDeep,
        ),
      );
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final base = Theme.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: isDark ? const Color(0xFF60A5FA) : RC.navy,
        ),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : RC.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [RC.navy, RC.navyDeep],
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isGuest
                                ? (lang == 'en'
                                      ? 'Guest Complaint'
                                      : (lang == 'ar'
                                            ? 'شكوى زائر'
                                            : 'Misafir Şikayet'))
                                : rt(lang, 'title'),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            widget.isGuest
                                ? (lang == 'en'
                                      ? 'Submit complaint without login'
                                      : (lang == 'ar'
                                            ? 'تقديم شكوى دون تسجيل'
                                            : 'Üye olmadan doğrudan bildirim'))
                                : (lang == 'en'
                                      ? 'Snap, locate & send to municipality'
                                      : (lang == 'ar'
                                            ? 'التقط وحدد وأرسل للبلدية'
                                            : 'Fotoğrafla, konum seç, belediyeye ilet')),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: rt(lang, 'my_title'),
                      icon: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProfileScreen(openRequestsOnStart: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Stepper(
          type: StepperType.vertical,
          physics: const ClampingScrollPhysics(),
          currentStep: _step,
          onStepTapped: (i) {
            if (i < _step && !_sending) {
              setState(() {
                _stepError = null;
                _step = i;
              });
            }
          },
          controlsBuilder: (context, details) => _controls(lang),
          steps: [
            _buildStep(0, rt(lang, 'step_photo'), _photoStep(lang)),
            _buildStep(1, rt(lang, 'step_location'), _locationStep(lang)),
            _buildStep(2, rt(lang, 'step_category'), _categoryStep(lang)),
            _buildStep(3, rt(lang, 'step_desc'), _descriptionStep(lang)),
            _buildStep(4, rt(lang, 'step_summary'), _summaryStep(lang)),
          ],
        ),
      ),
    );
  }

  Step _buildStep(int index, String title, Widget content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Step(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDark ? Colors.white : RC.textDark,
        ),
      ),
      isActive: _step >= index,
      state: _step > index ? StepState.complete : StepState.indexed,
      content: Align(alignment: Alignment.centerLeft, child: content),
    );
  }

  Widget _controls(String lang) {
    final isLast = _step == _lastStep;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_stepError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: RC.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _stepError!,
                      style: const TextStyle(
                        color: RC.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _sending
                        ? null
                        : () => isLast ? _submit(lang) : _next(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RC.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(rt(lang, isLast ? 'btn_send' : 'btn_next')),
                  ),
                ),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _sending ? null : _back,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF60A5FA)
                            : RC.navy,
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF60A5FA)
                              : RC.navy,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(rt(lang, 'btn_back')),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 1) Fotoğraf
  Widget _photoStep(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rt(lang, 'photo_hint'),
          style: const TextStyle(fontSize: 13, color: RC.textMuted),
        ),
        const SizedBox(height: 12),
        if (_photo != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _photo!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera, lang),
                icon: const Icon(Icons.photo_camera_rounded),
                label: Text(
                  _photo == null
                      ? rt(lang, 'btn_camera')
                      : rt(lang, 'photo_change'),
                ),
                style: _outlinedStyle(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery, lang),
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(rt(lang, 'btn_gallery')),
                style: _outlinedStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _outlinedStyle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? const Color(0xFF60A5FA) : RC.navy,
      side: BorderSide(color: isDark ? const Color(0xFF60A5FA) : RC.navy),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // 2) Konum
  Widget _locationStep(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(rt(lang, 'loc_auto')),
            ),
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
              label: Text(rt(lang, 'loc_manual')),
            ),
          ],
          selected: {_autoLocation},
          onSelectionChanged: (s) {
            setState(() {
              _autoLocation = s.first;
              _stepError = null;
            });
            if (_autoLocation && _position == null && !_locating) {
              _detectLocation();
            }
          },
        ),
        const SizedBox(height: 12),
        if (_autoLocation) ...[
          if (_locating)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(rt(lang, 'loc_detecting')),
              ],
            )
          else if (_position != null)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: RC.green,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${rt(lang, 'loc_detected')}${_address != null ? ': $_address' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _detectLocation,
                  child: Text(rt(lang, 'loc_retry')),
                ),
              ],
            )
          else if (_locationErrorKey != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rt(lang, _locationErrorKey!),
                  style: const TextStyle(color: RC.danger, fontSize: 12.5),
                ),
                TextButton.icon(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(rt(lang, 'loc_retry')),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          // Seçili değer dışarıdan değişebildiği için key ile yeniden kurulur.
          key: ValueKey('hood_${_neighborhood ?? 'none'}'),
          initialValue: _neighborhood,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : RC.textDark,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: rt(lang, 'loc_neighborhood'),
            labelStyle: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : null,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : RC.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : RC.border,
              ),
            ),
          ),
          items: kReportNeighborhoods
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      color: isDark ? Colors.white : RC.textDark,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() {
            _neighborhood = v;
            _stepError = null;
          }),
        ),
      ],
    );
  }

  // 3) Kategori
  Widget _categoryStep(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in kReportCategories)
          ChoiceChip(
            avatar: Icon(
              c.icon,
              size: 18,
              color: _category == c.key
                  ? Colors.white
                  : (isDark ? const Color(0xFF60A5FA) : RC.navy),
            ),
            label: Text(rt(lang, 'cat_${c.key}')),
            selected: _category == c.key,
            showCheckmark: false,
            selectedColor: isDark ? const Color(0xFF2563EB) : RC.navy,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: _category == c.key
                  ? Colors.white
                  : (isDark ? Colors.white : RC.textDark),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _category == c.key
                    ? (isDark ? const Color(0xFF2563EB) : RC.navy)
                    : (isDark ? const Color(0xFF334155) : RC.border),
              ),
            ),
            onSelected: (_) => setState(() {
              _category = c.key;
              _stepError = null;
            }),
          ),
      ],
    );
  }

  // 4) Açıklama
  Widget _descriptionStep(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _descCtrl,
      maxLines: 4,
      maxLength: 500,
      style: TextStyle(color: isDark ? Colors.white : null),
      onChanged: (_) {
        if (_stepError != null) setState(() => _stepError = null);
      },
      decoration: InputDecoration(
        hintText: rt(lang, 'desc_hint'),
        hintStyle: const TextStyle(fontSize: 13, color: RC.textMuted),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : RC.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : RC.border,
          ),
        ),
      ),
    );
  }

  // 5) Özet
  Widget _summaryStep(String lang) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF0F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7E0EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: RC.textDark,
              ),
              const SizedBox(width: 8),
              Text(
                rt(lang, 'summary_title'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (_photo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _photo!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          row(
            rt(lang, 'sum_category'),
            _category == null ? '-' : rt(lang, 'cat_$_category'),
            bold: true,
          ),
          row(
            rt(lang, 'sum_location'),
            _locationText.isEmpty ? '-' : _locationText,
          ),
          row(
            rt(lang, 'sum_photo'),
            _photo == null ? '-' : rt(lang, 'sum_photo_ok'),
          ),
          row(rt(lang, 'sum_desc'), _descCtrl.text.trim()),
        ],
      ),
    );
  }
}
