import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 15,
    this.borderRadius = 20,
    this.color,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.2,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlowingCircle extends StatelessWidget {
  final Color color;
  final double radius;
  final double blurRadius;

  const GlowingCircle({
    super.key,
    required this.color,
    this.radius = 40,
    this.blurRadius = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: blurRadius,
            spreadRadius: blurRadius / 2,
          ),
        ],
      ),
    );
  }
}
