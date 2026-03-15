
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedNotificationIcon extends StatefulWidget {
  final int notificationCount;
  final VoidCallback onPressed;

  const AnimatedNotificationIcon({
    Key? key,
    required this.notificationCount,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<AnimatedNotificationIcon> createState() =>
      _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    /// Bell swing animation (left-right like real bell)
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.35), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.35, end: 0.35), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: -0.25), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.25, end: 0.25), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    /// Small bounce effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    /// Trigger bell animation every few seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && widget.notificationCount > 0) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              alignment: Alignment.topCenter, // pivot like hanging bell
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none,
              size: 40,
              color: Colors.black,
            ),
            onPressed: widget.onPressed,
          ),
        ),

        /// Notification badge
        if (widget.notificationCount > 0)
          Positioned(
            right: 6,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

