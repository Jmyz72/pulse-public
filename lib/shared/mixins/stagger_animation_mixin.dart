import 'package:flutter/material.dart';

import '../../core/constants/app_animations.dart';

/// Mixin that provides stagger entrance animation capability to StatefulWidgets.
///
/// Usage:
/// 1. Add `with StaggerAnimationMixin` to your State class
/// 2. Override `staggerCount` with the number of stagger groups
/// 3. Call `startStaggerAnimation()` in `initState()`
/// 4. Wrap each group with `staggerIn(index: n, child: widget)`
///
/// Example:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with StaggerAnimationMixin {
///   @override
///   int get staggerCount => 3;
///
///   @override
///   void initState() {
///     super.initState();
///     startStaggerAnimation();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         staggerIn(index: 0, child: Text('First')),
///         staggerIn(index: 1, child: Text('Second')),
///         staggerIn(index: 2, child: Text('Third')),
///       ],
///     );
///   }
/// }
/// ```
mixin StaggerAnimationMixin<T extends StatefulWidget> on State<T> {
  /// Number of stagger groups (override in implementing class)
  int get staggerCount;

  late final List<bool> _staggerVisible;

  @override
  void initState() {
    super.initState();
    _staggerVisible = List.filled(staggerCount, false);
  }

  /// Call in initState to start the stagger animation sequence
  void startStaggerAnimation() {
    for (int i = 0; i < staggerCount; i++) {
      Future.delayed(AppAnimations.staggerDelay * i, () {
        if (mounted) {
          setState(() => _staggerVisible[i] = true);
        }
      });
    }
  }

  /// Wrap a widget with stagger entrance animation
  Widget staggerIn({required int index, required Widget child}) {
    final visible = index < _staggerVisible.length && _staggerVisible[index];
    return AnimatedOpacity(
      duration: AppAnimations.staggerElement,
      curve: AppAnimations.defaultCurve,
      opacity: visible ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: AppAnimations.staggerElement,
        curve: AppAnimations.defaultCurve,
        transform: Matrix4.translationValues(
          0,
          visible ? 0 : AppAnimations.slideOffset,
          0,
        ),
        child: child,
      ),
    );
  }
}
