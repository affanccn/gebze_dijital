import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

Future<bool> openDirections({
  required double lat,
  required double lng,
  String? label,
}) {
  final uri = Platform.isIOS
      ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d')
      : Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
        );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
