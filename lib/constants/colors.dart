import 'package:flutter/material.dart';

class ColorConstants {
  static Color redColor = hexToColor('#7E2D2D');
  static Color blueColor = hexToColor('#2D4D7E');
  static Color pinkColor = hexToColor('#7E2D62');
  static Color greenColor = hexToColor('#2D7E44');
}

Color hexToColor(String hex) {
  assert(RegExp(r'^#([0-9a-fA-F]{6})|([0-9a-fA-F]{8})$').hasMatch(hex));

  return Color(int.parse(hex.substring(1), radix: 16) +
      (hex.length == 7 ? 0xFF000000 : 0x00000000));
}
