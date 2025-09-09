import 'package:flutter/material.dart';

class AnimateIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color? hoverColor;
  final Duration duration;
  final VoidCallback onPressed;
  final bool clockwise;

  const AnimateIcon({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.size = 24.0,
    this.color = Colors.black,
    this.hoverColor,
    this.duration = const Duration(milliseconds: 300),
    this.clockwise = true,
  }) : super(key: key);

  @override
  _AnimateIconState createState() => _AnimateIconState();
}

class _AnimateIconState extends State<AnimateIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.clockwise ? 1 : -1,
    ).animate(_controller);
    _controller.forward();
    _animation.addStatusListener((status){
        if(status == AnimationStatus.completed){
          _controller.forward();
        }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_controller.isAnimating) return;

    await _controller.forward();
    _controller.reset();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: RotationTransition(
          turns: _animation,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
