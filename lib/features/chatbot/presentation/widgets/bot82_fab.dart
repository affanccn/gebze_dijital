import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/bot82_state.dart';
import 'bot82_tilt_source.dart';
import 'gebze_robot_asset.dart';

const _cyan = Color(0xFF22D3EE);

const double kBot82Aspect = 0.724;

const Rect kBot82FaceRect = Rect.fromLTWH(0.34, 0.09, 0.30, 0.18);

class Bot82Fab extends ConsumerStatefulWidget {
  const Bot82Fab({
    super.key,
    required this.onTap,
    this.width = 88,
    this.aspect = kBot82Aspect,
    this.bodyAsset = 'assets/images/gebzechatbot.png',
    this.headAsset,
    this.faceRect = kBot82FaceRect,
    this.artBuilder,
    this.tiltSource,
  });

  final VoidCallback onTap;
  final double width;
  final double aspect;
  final String bodyAsset;
  final String? headAsset;
  final Rect faceRect;
  final WidgetBuilder? artBuilder;
  final Bot82TiltSource? tiltSource;

  double get height => width / aspect;
  double get totalHeight => height + width * 0.2;

  @override
  ConsumerState<Bot82Fab> createState() => _Bot82FabState();
}

class _Bot82FabState extends ConsumerState<Bot82Fab>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _float;
  late final AnimationController _think;
  late final AnimationController _blend;
  late final AnimationController _tap;
  late final Animation<double> _heart;
  late final Bot82TiltSource _tilt;
  late final bool _ownsTilt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _think = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _heart = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.6,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 9,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 55),
    ]).animate(_think);

    _blend =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addStatusListener((s) {
          if (s == AnimationStatus.dismissed) _think.stop();
        });

    _tap = AnimationController.unbounded(vsync: this, value: 0);

    _ownsTilt = widget.tiltSource == null;
    _tilt = widget.tiltSource ?? Bot82TiltSource();
    _tilt.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_float.isAnimating) _float.repeat(reverse: true);
      _tilt.start();
    } else {
      _float.stop();
      _tilt.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsTilt) _tilt.dispose();
    _float.dispose();
    _think.dispose();
    _blend.dispose();
    _tap.dispose();
    super.dispose();
  }

  void _onMode(Bot82Mode? prev, Bot82Mode next) {
    if (next == Bot82Mode.thinking) {
      if (!_think.isAnimating) _think.repeat();
      _blend.forward();
    } else {
      _blend.reverse();
    }
    if (next == Bot82Mode.tapped) _bounce();
  }

  void _bounce() {
    const spring = SpringDescription(mass: 1, stiffness: 220, damping: 14);
    _tap.animateWith(SpringSimulation(spring, -0.55, 0.0, 15.0));
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    ref.read(bot82Provider.notifier).registerTap();
    _bounce();
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Bot82Mode>(bot82Provider.select((s) => s.mode), _onMode);

    final w = widget.width;
    final h = widget.height;

    final art =
        widget.artBuilder?.call(context) ??
        buildGebzeRobotImage(width: w, height: h, fit: BoxFit.contain);

    return Semantics(
      button: true,
      label: 'Gebze Dijital Asistanı, sohbeti aç',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: RepaintBoundary(
          child: SizedBox(
            width: w,
            height: widget.totalHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _float,
                _think,
                _blend,
                _tap,
                _tilt.tilt,
              ]),
              child: art,
              builder: (context, child) => _compose(w, h, child!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compose(double w, double h, Widget art) {
    final amp = w * 0.05;
    final f = Curves.easeInOutSine.transform(_float.value);
    final floatY = -(f * 2 - 1) * amp;
    final tilt = _tilt.tilt.value;
    final blend = _blend.value;
    final heart = _heart.value;
    final tap = _tap.value;
    final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * _think.value);

    final jumpY = -tap * w * 0.32;
    final scaleY = (1 + tap * 0.12) * (1 + 0.07 * heart * blend);
    final scaleX = (1 - tap * 0.07) * (1 + 0.07 * heart * blend);

    final altitude = (f * 0.5 + tap.clamp(0.0, 1.2) * 0.8).clamp(0.0, 1.2);
    final shadowScale = 1 - 0.2 * altitude;
    final shadowOpacity = (0.34 - 0.16 * altitude).clamp(0.05, 0.4);

    final perspective = Matrix4.identity()
      ..setEntry(3, 2, 0.0014)
      ..rotateX(-tilt.dy * 0.30)
      ..rotateY(tilt.dx * 0.38);

    Widget body = ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment(-1.4 - tilt.dx * 1.2, -1 - tilt.dy * 0.6),
        end: Alignment(0.6 - tilt.dx * 1.2, 1 - tilt.dy * 0.6),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.30),
          Colors.transparent,
        ],
        stops: const [0.35, 0.5, 0.65],
      ).createShader(r),
      child: art,
    );

    body = ColorFiltered(
      colorFilter: ColorFilter.mode(
        _cyan.withValues(alpha: 0.16 * blend * (0.4 + 0.6 * pulse)),
        BlendMode.srcATop,
      ),
      child: body,
    );

    final shift = Offset(tilt.dx * w * 0.025, tilt.dy * w * 0.015);

    final robot = SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (blend > 0.01)
            Positioned(
              left: -w * 0.1,
              right: -w * 0.1,
              top: h * 0.02,
              height: w * 1.2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _cyan.withValues(
                        alpha: 0.30 * blend * (0.5 + 0.5 * pulse),
                      ),
                      _cyan.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          Transform.translate(offset: shift, child: body),
          if (widget.headAsset != null)
            Transform.translate(
              offset: Offset(tilt.dx * w * 0.06, tilt.dy * w * 0.035),
              child: Image.asset(
                widget.headAsset!,
                width: w,
                height: h,
                fit: BoxFit.contain,
              ),
            ),
          if (blend > 0.01)
            Positioned(
              left: w * widget.faceRect.left + shift.dx,
              top: h * widget.faceRect.top + shift.dy,
              width: w * widget.faceRect.width,
              height: h * widget.faceRect.height,
              child: CustomPaint(
                painter: Bot82ThinkingFacePainter(_think.value, blend),
              ),
            ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.translate(
              offset: Offset(-tilt.dx * w * 0.07, 0),
              child: Transform.scale(
                scale: shadowScale,
                child: CustomPaint(
                  size: Size(w * 0.62, w * 0.12),
                  painter: _ShadowPainter(shadowOpacity),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: w * 0.06,
          child: Transform.translate(
            offset: Offset(0, floatY + jumpY),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
              child: Transform(
                alignment: Alignment.center,
                transform: perspective,
                child: robot,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter(this.opacity);
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1, size.height / size.width);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: opacity),
            Colors.black.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.opacity != opacity;
}

class Bot82ThinkingFacePainter extends CustomPainter {
  const Bot82ThinkingFacePainter(this.phase, this.blend);
  final double phase;
  final double blend;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height * 0.28),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF05080C).withValues(alpha: blend),
    );

    final gap = size.width * 0.22;
    for (var i = 0; i < 3; i++) {
      final s = 0.5 + 0.5 * math.sin(2 * math.pi * (phase - i * 0.16));
      final c = Offset(size.width / 2 + (i - 1) * gap, size.height / 2);
      final r = size.height * (0.075 + 0.045 * s);
      canvas.drawCircle(
        c,
        r * 2.2,
        Paint()..color = _cyan.withValues(alpha: 0.18 * s * blend),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()..color = _cyan.withValues(alpha: (0.45 + 0.55 * s) * blend),
      );
    }
  }

  @override
  bool shouldRepaint(Bot82ThinkingFacePainter old) =>
      old.phase != phase || old.blend != blend;
}
