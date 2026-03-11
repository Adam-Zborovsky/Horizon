import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../core/theme/app_theme.dart';
import 'wear_glass_card.dart';

/// A UI component for Wear OS that displays the refresh status.
/// Designed to be revealed from behind the list content with proper padding.
class WearRefreshIndicator extends StatelessWidget {
  final IndicatorController controller;
  final double height;
  final VoidCallback? onTap;
  final bool isActuallyLoading;

  const WearRefreshIndicator({
    super.key,
    required this.controller,
    required this.height,
    this.onTap,
    this.isActuallyLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bool isArmed = controller.isArmed;
        final bool isSnappedOpen = controller.state.isLoading;
        
        // Final opacity and scale based on pull progress
        final double revealValue = controller.value.clamp(0.0, 1.0);
        final double opacity = (revealValue * 2.0).clamp(0.0, 1.0);
        final double scale = 0.8 + (revealValue * 0.2);

        return Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          // Transparent background to let the main app gradient show through
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: (isSnappedOpen && !isActuallyLoading) ? onTap : null,
                  child: WearGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    borderRadius: 24,
                    color: isActuallyLoading 
                        ? AppTheme.goldAmber.withOpacity(0.25) 
                        : (isSnappedOpen ? AppTheme.goldAmber.withOpacity(0.15) : AppTheme.goldAmber.withOpacity(0.05)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActuallyLoading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.goldAmber,
                            ),
                          )
                        else
                          Icon(
                            isSnappedOpen 
                                ? Icons.refresh_rounded 
                                : (isArmed ? Icons.keyboard_double_arrow_down_rounded : Icons.keyboard_double_arrow_up_rounded), 
                            color: AppTheme.goldAmber, 
                            size: 16
                          ),
                        const SizedBox(width: 10),
                        Text(
                          isActuallyLoading 
                              ? 'UPDATING' 
                              : (isSnappedOpen ? 'REFRESH' : (isArmed ? 'RELEASE' : 'PULL UP')),
                          style: const TextStyle(
                            color: AppTheme.goldAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
