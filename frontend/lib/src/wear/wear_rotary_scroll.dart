import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

/// Wraps a scrollable child to support rotary input (rotating bezel/crown)
/// on Wear OS devices like the Galaxy Watch Classic.
///
/// Uses the wearable_rotary plugin for hardware events and provides
/// smooth interpolation and haptic feedback.
class WearRotaryScroll extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  
  /// Distance in pixels to scroll per rotary "click"
  final double scrollStep;
  
  /// Duration of the smoothing animation
  final Duration animationDuration;

  const WearRotaryScroll({
    super.key,
    required this.controller,
    required this.child,
    this.scrollStep = 45.0, // Optimized for Galaxy Watch bezel
    this.animationDuration = const Duration(milliseconds: 120),
  });

  @override
  State<WearRotaryScroll> createState() => _WearRotaryScrollState();
}

class _WearRotaryScrollState extends State<WearRotaryScroll> {
  StreamSubscription? _subscription;
  double _targetOffset = 0;

  @override
  void initState() {
    super.initState();
    _targetOffset = widget.controller.hasClients ? widget.controller.offset : 0;
    
    // Listen to manual scrolls to keep _targetOffset in sync
    widget.controller.addListener(_syncTargetOffset);
    
    _subscription = rotaryEvents.listen((RotaryEvent event) {
      if (!widget.controller.hasClients) return;

      // Update target based on rotation
      if (event.direction == RotaryDirection.clockwise) {
        _targetOffset += widget.scrollStep;
      } else {
        _targetOffset -= widget.scrollStep;
      }

      // Clamp target
      _targetOffset = _targetOffset.clamp(
        widget.controller.position.minScrollExtent - 50, // Allow slight overscroll
        widget.controller.position.maxScrollExtent + 50,
      );

      // Animate smoothly
      widget.controller.animateTo(
        _targetOffset.clamp(
           widget.controller.position.minScrollExtent,
           widget.controller.position.maxScrollExtent,
        ),
        duration: widget.animationDuration,
        curve: Curves.easeOutCubic,
      );

      // Provide subtle tactile feedback for each tick
      HapticFeedback.lightImpact();
    });
  }

  void _syncTargetOffset() {
    if (widget.controller.hasClients) {
      // If the current offset is very different from target (manual swipe), sync them
      if ((widget.controller.offset - _targetOffset).abs() > 10) {
        _targetOffset = widget.controller.offset;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTargetOffset);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && widget.controller.hasClients) {
          _targetOffset = widget.controller.offset + event.scrollDelta.dy;
          
          widget.controller.animateTo(
            _targetOffset.clamp(
              widget.controller.position.minScrollExtent,
              widget.controller.position.maxScrollExtent,
            ),
            duration: widget.animationDuration,
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: widget.child,
    );
  }
}
