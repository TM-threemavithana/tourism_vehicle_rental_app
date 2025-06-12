import 'package:flutter/material.dart';
import 'slide_base.dart';

class SlideOne extends StatelessWidget {
  const SlideOne({super.key});

  @override
  Widget build(BuildContext context) {
    return const SlideBase(
      title: 'Discover Local Rides',
      description:
          'Explore Sri Lanka\'s coastal beauty with our wide selection of rental vehicles.',
      imageUrl: 'assets/images/image1.jpg',
      bgColor: Color(0xFF1B7BC8),
    );
  }
}
