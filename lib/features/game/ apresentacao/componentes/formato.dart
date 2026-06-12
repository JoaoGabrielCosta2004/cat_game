import 'package:flutter/material.dart';

class HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    double width = size.width;
    double height = size.height;
    
    path.moveTo(width * 0.50, 0);
    
    path.lineTo(width * 0.93, height * 0.25);
    path.lineTo(width * 0.93, height * 0.75);
    path.lineTo(width * 0.50, height);
    path.lineTo(width * 0.07, height * 0.75);
    path.lineTo(width * 0.07, height * 0.25);
    
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
