import 'package:flutter/material.dart';

class SlideBase extends StatelessWidget {
  final String title;
  final String description;
  final IconData? iconData;
  final Color bgColor;
  final String? imageUrl;

  const SlideBase({
    super.key,
    required this.title,
    required this.description,
    this.iconData,
    required this.bgColor,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Background image with gradient overlay - simplified without loading state
          if (imageUrl != null)
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor.withOpacity(0.3),
                      bgColor.withOpacity(0.9),
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcATop,
                child: _buildImage(imageUrl!, BoxFit.cover),
              ),
            ),

          // Decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Main content column
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Main visual - simplified image loading
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildImage(imageUrl!, BoxFit.cover),
                      ),
                    ),
                  )
                else if (iconData != null)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),

                const Spacer(),

                // Content card with text
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for displaying images
  Widget _buildImage(String url, BoxFit fit) {
    return Image.asset(
      url,
      fit: fit,
      gaplessPlayback: true, // Prevents flashes between slides
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // This ensures we always show something, even if image isn't fully loaded
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }

        // Show a placeholder with fade-in when the image loads
        return Container(
          color: bgColor.withOpacity(0.5),
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Wave painter for subtle wave effect
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(0, size.height);

    // Create a wave pattern
    double waveHeight = 20;
    int waves = 4;

    for (int i = 0; i <= waves; i++) {
      double startX = size.width * i / waves;
      double endX = size.width * (i + 1) / waves;
      double midX = (startX + endX) / 2;

      if (i == 0) {
        path.lineTo(startX, size.height - waveHeight);
      }

      path.quadraticBezierTo(
          midX, size.height - (waveHeight * 2), endX, size.height - waveHeight);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.color != color;
}
