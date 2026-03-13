import 'dart:async';
import 'package:flutter/material.dart';

enum BounceDirection {
  up,
  down,
  left,
  right,
  center,
}

class AnimatedNotificationIcon extends StatefulWidget {
  final int notificationCount;
  final VoidCallback onPressed;
  final BounceDirection direction;

  const AnimatedNotificationIcon({
    Key? key,
    required this.notificationCount,
    required this.onPressed,
    this.direction = BounceDirection.up,
  }) : super(key: key);

  @override
  State<AnimatedNotificationIcon> createState() =>
      _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.notificationCount > 0) {
        _controller.forward(from: 0);
      }
    });
  }

  Offset _getOffset(double value) {
    switch (widget.direction) {
      case BounceDirection.up:
        return Offset(0, -value.abs());
      case BounceDirection.down:
        return Offset(0, value.abs());
      case BounceDirection.left:
        return Offset(-value.abs(), 0);
      case BounceDirection.right:
        return Offset(value.abs(), 0);
      case BounceDirection.center:
        return Offset(value, 0); // shake effect
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (_, child) {
            return Transform.translate(
              offset: _getOffset(_animation.value),
              child: child,
            );
          },
          child: IconButton(
            icon: const Icon(
              Icons.mail_outline_outlined,
              size: 30,
              color: Colors.black,
            ),
            onPressed: widget.onPressed,
          ),
        ),
        if (widget.notificationCount > 0)
          Positioned(
            right: 7,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}