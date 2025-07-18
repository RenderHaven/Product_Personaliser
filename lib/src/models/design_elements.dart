import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ElementType { text, image }

class TextWidget {
  String title;
  String font;
  Color color;

  TextWidget({
    this.title = 'Title',
    this.color = Colors.black,
    this.font = 'Roboto',
  });

  Widget getText() {
    return Text(
      title,
      style: GoogleFonts.getFont(font, color: color, fontSize: 100),
      textAlign: TextAlign.center,
    );
  }
}

class DesignElement {
  final String id;
  ElementType type;
  double x;
  double y;
  double width;
  double height;
  TextWidget? textWidget;
  String? imageUrl;

  DesignElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.imageUrl,
    this.textWidget,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory DesignElement.fromJson(Map<String, dynamic> json) {
    return DesignElement(
      id: json['id'],
      type: ElementType.values.firstWhere((e) => e.name == json['type']),
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
    );
  }
}
