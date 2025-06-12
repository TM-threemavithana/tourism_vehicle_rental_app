import 'package:flutter/material.dart';
import 'slide_base.dart';

class SlideTwo extends StatelessWidget {
  const SlideTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SlideBase(
      title: 'Easy Booking',
      description:
          'Quick and hassle-free booking process with flexible rental periods.',
      imageUrl: 'assets/images/image2.jpg',
      bgColor: Color(0xFF2CDCAD),
    );
  }
}
