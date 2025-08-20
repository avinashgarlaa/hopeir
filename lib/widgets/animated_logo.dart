import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  const AnimatedLogo(double d, {super.key, this.size = 150});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Center(
            child: Text(
              'H',
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: const Color(0xff5b2c6f), // deep purple
                letterSpacing: 6,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.25),
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
