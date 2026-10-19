import 'package:flutter/material.dart';

import '../models/gebze_avatar.dart';
import '../services/avatar_crop_service.dart';

/// Gebze Temalı Hazır Avatarlar ve 500x500 Kare Kırpmalı Galeri Seçim Penceresi
class GebzeAvatarPickerSheet extends StatefulWidget {
  final String currentAvatarUrl;
  final Function(String selectedAvatarUrl) onAvatarSelected;

  const GebzeAvatarPickerSheet({
    super.key,
    required this.currentAvatarUrl,
    required this.onAvatarSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentAvatarUrl,
    required Function(String selectedAvatarUrl) onAvatarSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 380),
        reverseDuration: Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      ),
      builder: (_) => GebzeAvatarPickerSheet(
        currentAvatarUrl: currentAvatarUrl,
        onAvatarSelected: onAvatarSelected,
      ),
    );
  }

  @override
  State<GebzeAvatarPickerSheet> createState() => _GebzeAvatarPickerSheetState();
}

class _GebzeAvatarPickerSheetState extends State<GebzeAvatarPickerSheet> {
  late String _selectedUrl;
  bool _isProcessing = false;
  String? _customCroppedAvatar;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.currentAvatarUrl;
    if (_selectedUrl.startsWith('data:image')) {
      _customCroppedAvatar = _selectedUrl;
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);
    final cropped = await AvatarCropService.pickAndCropFromGallery();
    setState(() => _isProcessing = false);

    if (cropped != null) {
      setState(() {
        _customCroppedAvatar = cropped;
        _selectedUrl = cropped;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isProcessing = true);
    final cropped = await AvatarCropService.pickAndCropFromCamera();
    setState(() => _isProcessing = false);

    if (cropped != null) {
      setState(() {
        _customCroppedAvatar = cropped;
        _selectedUrl = cropped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    const avatars = kGebzeAvatars;

    return Container(
      height: size.height * 0.82,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 14),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil Fotoğrafı Seçin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0A1F44),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hazır avatar seçin veya galeriden 500×500 px kare fotoğraf yükleyin',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Galeri & Kamera Aksiyon Butonları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _UploadOptionCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Galeriden Seç',
                    subtitle: '500×500 Kare Kırp',
                    isDark: isDark,
                    onTap: _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _UploadOptionCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Kamera',
                    subtitle: 'Anlık Fotoğraf Çek',
                    isDark: isDark,
                    onTap: _pickFromCamera,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Eğer Galeriden kırpılmış görsel varsa özel önizleme rozeti
          if (_customCroppedAvatar != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedUrl = _customCroppedAvatar!);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedUrl == _customCroppedAvatar
                        ? const Color(0xFF0A2A66).withAlpha(isDark ? 50 : 20)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedUrl == _customCroppedAvatar
                          ? const Color(0xFFFF7A00)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: _selectedUrl == _customCroppedAvatar ? 2.2 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: getAvatarImageProvider(_customCroppedAvatar)!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yüklediğiniz Fotoğraf (500×500 px)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0A1F44),
                              ),
                            ),
                            const Text(
                              'Otomatik kare kırpıldı ve optimize edildi',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedUrl == _customCroppedAvatar)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFFF7A00),
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Avatarlar Grid'i
          Expanded(
            child: _isProcessing
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Görsel 500×500 px kare kırpılıyor...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.90,
                    ),
                    itemCount: avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = avatars[index];
                      final isSelected = _selectedUrl == avatar.assetPath;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedUrl = avatar.assetPath);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0A2A66).withAlpha(isDark ? 60 : 20)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF7A00)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2.5 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF7A00).withAlpha(60),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage: AssetImage(avatar.assetPath),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF7A00),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                              if (avatar.titleTr.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  avatar.titleTr,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFFFF7A00)
                                        : (isDark ? Colors.white : const Color(0xFF0A1F44)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Alt Onay Çubuğu
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Vazgeç',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onAvatarSelected(_selectedUrl);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Fotoğrafı Kaydet',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2A66),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
}

class _UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5FD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withAlpha(isDark ? 50 : 25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFF7A00), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
