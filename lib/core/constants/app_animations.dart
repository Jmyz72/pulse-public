import 'package:flutter/material.dart';

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration staggerElement = Duration(milliseconds: 350);
  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Duration shake = Duration(milliseconds: 300);
  static const Duration pulse = Duration(milliseconds: 1500);
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const double slideOffset = 30.0;
  static const double shakeOffset = 8.0;
}
