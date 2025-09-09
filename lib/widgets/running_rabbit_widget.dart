import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math'; // For Random

class RunningRabbitWidget extends StatefulWidget {
  const RunningRabbitWidget({super.key});

  @override
  State<RunningRabbitWidget> createState() => _RunningRabbitWidgetState();
}

class _RunningRabbitWidgetState extends State<RunningRabbitWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animationX;
  double _amplitude = 20.0; // Initial amplitude

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // Increased duration to reduce speed
      vsync: this,
    )..repeat();

    // Listener to randomize amplitude on each cycle completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _amplitude = Random().nextDouble() * 30 + 10; // Random amplitude between 10 and 40
        });
      }
    });

    // Animation setup will be finalized in build to access context
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    _animationX = Tween<double>(begin: -50, end: screenWidth).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    return SizedBox(
      height: 200, // Adjust height as needed
      width: double.infinity,
      // No background color for transparency
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double jumpOffset = math.sin(_controller.value * math.pi * 4) * _amplitude; // Use variable amplitude
          return Transform.translate(
            offset: Offset(_animationX.value, jumpOffset),
            child: const Text(
              '🐰', // Rabbit emoji
              style: TextStyle(fontSize: 50),
            ),
          );
        },
      ),
    );
  }
}