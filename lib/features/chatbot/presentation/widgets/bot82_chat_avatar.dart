import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'bot82_fab.dart';
import 'gebze_robot_asset.dart';

class Bot82ChatAvatar extends StatefulWidget {
  const Bot82ChatAvatar({
    super.key,
    this.size = 44,
    this.animated = false,
    this.thinking = false,
    this.heightFactor = 0.58,
    this.asset = 'assets/images/gebzechatbot.png',
  });

  final double size;
  final bool animated;
  final bool thinking;
  final double heightFactor;
  final String asset;

  @override
  State<Bot82ChatAvatar> createState() => _Bot82ChatAvatarState();
}

class _Bot82ChatAvatarState extends State<Bot82ChatAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Bot82ChatAvatar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.animated || widget.thinking) {
      if (!_float.isAnimating) _float.repeat(reverse: true);
    } else {
      _float
        ..stop()
        ..value = 0;
    }
    if (widget.thinking) {
      if (!_beat.isAnimating) _beat.repeat();
    } else {
      _beat
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final fullH = w / kBot82Aspect;

    final image = buildGebzeRobotImage(
      width: w,
      height: fullH,
      fit: BoxFit.contain,
    );

    Widget framed(Widget content) => SizedBox(
      width: w,
      height: fullH * widget.heightFactor,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: widget.heightFactor,
          child: SizedBox(width: w, height: fullH, child: content),
        ),
      ),
    );

    if (!widget.animated && !widget.thinking) return framed(image);

    return AnimatedBuilder(
      animation: Listenable.merge([_float, _beat]),
      child: image,
      builder: (context, img) {
        final t = Curves.easeInOutSine.transform(_float.value);
        final dy = -(t * 2 - 1) * w * 0.035;
        final pulse = widget.thinking
            ? 0.5 + 0.5 * math.sin(2 * math.pi * _beat.value)
            : 0.0;
        final face = kBot82FaceRect;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: 1 + 0.06 * pulse,
            alignment: Alignment.bottomCenter,
            child: framed(
              Stack(
                children: [
                  img!,
                  if (widget.thinking)
                    Positioned(
                      left: w * face.left,
                      top: fullH * face.top,
                      width: w * face.width,
                      height: fullH * face.height,
                      child: CustomPaint(
                        painter: Bot82ThinkingFacePainter(_beat.value, 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class Bot82MessageRow extends StatelessWidget {
  const Bot82MessageRow({
    super.key,
    required this.bubble,
    this.isLatest = false,
    this.thinking = false,
    this.avatarSize = 44,
  });

  final Widget bubble;
  final bool isLatest;
  final bool thinking;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Bot82ChatAvatar(
            size: avatarSize,
            animated: isLatest,
            thinking: thinking,
          ),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
