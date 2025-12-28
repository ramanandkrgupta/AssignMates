import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedNotificationIcon extends StatefulWidget {
  final int unreadCount;
  final VoidCallback onTap;
  final Color iconColor;

  const AnimatedNotificationIcon({
    super.key,
    required this.unreadCount,
    required this.onTap,
    this.iconColor = Colors.black,
  });

  @override
  State<AnimatedNotificationIcon> createState() => _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    if (widget.unreadCount > 0) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(AnimatedNotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > oldWidget.unreadCount) {
      _startAnimation();
    } else if (widget.unreadCount == 0) {
      _controller.stop();
    } else if (widget.unreadCount > 0 && !_controller.isAnimating) {
       _startAnimation();
    }
  }

  void _startAnimation() async {
    if (!mounted) return;
    // Wiggle 3 times
    for (int i = 0; i < 3; i++) {
      await _controller.forward(from: 0.0);
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double rotation = math.sin(_controller.value * 2 * math.pi) * 0.2;
              return Transform.rotate(
                angle: rotation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.unreadCount > 0 ? Icons.notifications_active : Icons.notifications_none_outlined,
                    size: 26,
                    color: widget.unreadCount > 0 ? const Color(0xFFFFAF00) : widget.iconColor,
                  ),
                ),
              );
            },
          ),
          if (widget.unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          widget.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
