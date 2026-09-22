import 'package:flutter/material.dart';

class ClinicLogo extends StatelessWidget {
  final bool isCompact;
  final double height;

  const ClinicLogo({
    super.key,
    this.isCompact = false,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Image.asset(
        'assets/images/logo_icon.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.local_hospital_rounded,
          color: Color(0xFF0284C7),
          size: 32,
        ),
      );
    }

    return Image.asset(
      'assets/images/clinic_logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => const Text(
        'veebrosinfosolutions',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
