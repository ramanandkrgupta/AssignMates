import 'package:flutter/material.dart';

class InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const InAppNotificationWidget({
    Key? key,
    required this.title,
    required this.body,
    required this.onDismiss,
    this.onTap,
  }) : super(key: key);

  @override
  State<InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Start animation
    _controller.forward();

    // Auto hide after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100, // Below status bar
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) {
              widget.onDismiss();
            },
            child: GestureDetector(
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!();
                }
                _dismiss();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                color: const Color(0xFF323232), // Discord-like dark grey
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.body,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

void showInAppNotification(BuildContext context, String title, String body, {VoidCallback? onTap}) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => InAppNotificationWidget(
      title: title,
      body: body,
      onTap: onTap,
      onDismiss: () {
        overlayEntry?.remove();
        overlayEntry = null;
      },
    ),
  );

  Overlay.of(context).insert(overlayEntry!);
}
