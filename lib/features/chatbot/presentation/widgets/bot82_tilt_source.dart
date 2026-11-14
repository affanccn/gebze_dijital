import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class Bot82TiltSource {
  Bot82TiltSource({this.invertX = false, this.invertY = false});

  final bool invertX;
  final bool invertY;
  final ValueNotifier<Offset> tilt = ValueNotifier(Offset.zero);

  void start() {}

  void stop() {}

  void updateTilt(Offset newTilt) {
    final clamped = Offset(
      newTilt.dx.clamp(-1.0, 1.0) * (invertX ? -1 : 1),
      newTilt.dy.clamp(-1.0, 1.0) * (invertY ? -1 : 1),
    );
    tilt.value = clamped;
  }

  void dispose() {
    stop();
    tilt.dispose();
  }
}
