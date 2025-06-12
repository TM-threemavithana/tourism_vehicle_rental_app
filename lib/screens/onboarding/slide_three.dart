import 'package:flutter/material.dart';
import 'slide_base.dart';

class SlideThree extends StatelessWidget {
  const SlideThree({super.key});

  @override
  Widget build(BuildContext context) {
    return const SlideBase(
      title: 'Explore Your Way',
      description:
          'Enjoy the freedom to explore hidden beaches and local treasures at your own pace.',
      imageUrl: 'assets/images/image3.jpg',
      bgColor: Color(0xFFFFAA33),
    );
  }
}
