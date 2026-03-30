import 'package:flutter/material.dart';

import '../../../../shared/widgets/pulse_brand_mark.dart';

class AuthLogo extends StatelessWidget {
  final double size;

  const AuthLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return PulseBrandMark(size: size);
  }
}
