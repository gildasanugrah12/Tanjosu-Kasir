import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double blurSigma;
  final Border? border;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.backgroundColor,
    this.blurSigma = 16,
    this.border,
    this.width,
    this.height,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}
