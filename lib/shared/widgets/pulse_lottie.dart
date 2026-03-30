import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/constants/app_colors.dart';

class PulseLottie extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool repeat;
  final bool animate;
  final BoxFit fit;
  final String? semanticLabel;
  final Widget? fallback;
  final bool pauseWhenHidden;
  final RenderCache? renderCache;
  final bool backgroundLoading;

  const PulseLottie({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.repeat = true,
    this.animate = true,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.fallback,
    this.pauseWhenHidden = true,
    this.renderCache,
    this.backgroundLoading = true,
  });

  static Future<LottieComposition?> _decodeDotLottie(List<int> bytes) {
    return LottieComposition.decodeZip(
      bytes,
      filePicker: (files) {
        for (final file in files) {
          if (file.name.startsWith('animations/') &&
              file.name.endsWith('.json')) {
            return file;
          }
        }
        for (final file in files) {
          if (file.name.endsWith('.json')) {
            return file;
          }
        }
        return null;
      },
    );
  }

  @override
  State<PulseLottie> createState() => _PulseLottieState();
}

class _PulseLottieState extends State<PulseLottie> {
  late final Key _visibilityKey;
  double _visibleFraction = 1.0;

  @override
  void initState() {
    super.initState();
    _visibilityKey = UniqueKey();
  }

  bool _shouldAnimate(BuildContext context) {
    if (!widget.animate) return false;
    if (!TickerMode.of(context)) return false;
    if (!widget.pauseWhenHidden) return true;

    final isCurrentRoute = ModalRoute.isCurrentOf(context) ?? true;
    return isCurrentRoute && _visibleFraction > 0;
  }

  @override
  Widget build(BuildContext context) {
    final child = VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (info) {
        if ((_visibleFraction - info.visibleFraction).abs() < 0.001) return;
        if (!mounted) return;
        setState(() {
          _visibleFraction = info.visibleFraction;
        });
      },
      child: Lottie.asset(
        widget.assetPath,
          decoder: widget.assetPath.toLowerCase().endsWith('.lottie')
              ? PulseLottie._decodeDotLottie
              : null,
        width: widget.width,
        height: widget.height,
        repeat: widget.repeat,
        animate: _shouldAnimate(context),
        fit: widget.fit,
        renderCache: widget.renderCache,
        backgroundLoading: widget.backgroundLoading,
        errorBuilder: (context, error, stackTrace) {
          return widget.fallback ??
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 64,
                ),
              );
        },
      ),
    );

    if (widget.semanticLabel == null || widget.semanticLabel!.isEmpty) {
      return child;
    }

    return Semantics(label: widget.semanticLabel, image: true, child: child);
  }
}
