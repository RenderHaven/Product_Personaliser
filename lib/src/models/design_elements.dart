import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

enum ElementType { text, image }
class DesignElement {
  final String id;
  final Rx<ElementType> type;
  final RxDouble x;
  final RxDouble y;
  final RxDouble width;
  final RxDouble height;
  final Rx<TextWidget?> textWidget;
  final RxString? imageUrl;
  final RxBool isActive=true.obs;

  DesignElement({
    required this.id,
    required ElementType type,
    required double x,
    required double y,
    required double width,
    required double height,
    TextWidget? textWidget,
    String? imageUrl,
  })  : type = Rx<ElementType>(type),
        x = RxDouble(x),
        y = RxDouble(y),
        width = RxDouble(width),
        height = RxDouble(height),
        textWidget = Rx<TextWidget?>(textWidget),
        imageUrl = imageUrl != null ? RxString(imageUrl) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value.name,
        'x': x.value,
        'y': y.value,
        'width': width.value,
        'height': height.value,
        'textWidget': textWidget.value?.toJson(),
        'imageUrl': imageUrl?.value,
      };

  factory DesignElement.fromJson(Map<String, dynamic> json) {
    return DesignElement(
      id: json['id'],
      type: ElementType.values.firstWhere((e) => e.name == json['type']),
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
      textWidget: json['textWidget'] != null 
          ? TextWidget.fromJson(json['textWidget']) 
          : null,
      imageUrl: json['imageUrl'],
    );
  }

  /// Clean up all Rx observables when the element is no longer needed
  void dispose() {
    // Dispose the text widget if it exists
    textWidget.value?.dispose();
    textWidget.close();
    
    // Dispose image URL if it exists
    imageUrl?.close();
    
    // Dispose position and size observables
    x.close();
    y.close();
    width.close();
    height.close();
    isActive.close();
    
    // Dispose type observable
    type.close();
  }
}

class TextWidget {
  final RxString title;
  final RxString font;
  final Rx<Color> color;
  final RxDouble? size;
  final Rx<FontWeight?> weight;

  TextWidget({
    String title = 'Title',
    String font = 'Roboto',
    Color color = Colors.black,
    double? size,
    FontWeight? weight,
  })  : title = RxString(title),
        font = RxString(font),
        color = Rx<Color>(color),
        size = size != null ? RxDouble(size) : null,
        weight = Rx<FontWeight?>(weight);

  Widget getText() {
    return Obx(() => Text(
          title.value,
          style: GoogleFonts.getFont(
            font.value,
            color: color.value,
            fontSize: size?.value ?? 100,
            fontWeight: weight.value,
          ),
          textAlign: TextAlign.center,
        ));
  }

  Map<String, dynamic> toJson() => {
        'title': title.value,
        'font': font.value,
        'color': color.value.value,
        'size': size?.value,
        'weight': weight.value?.index,
      };

  factory TextWidget.fromJson(Map<String, dynamic> json) {
    return TextWidget(
      title: json['title'] ?? 'Title',
      font: json['font'] ?? 'Roboto',
      color: Color(json['color'] ?? Colors.black.value),
      size: json['size']?.toDouble(),
      weight: json['weight'] != null 
          ? FontWeight.values[json['weight'] as int] 
          : null,
    );
  }

  /// Clean up all Rx observables when the text widget is no longer needed
  void dispose() {
    title.close();
    font.close();
    color.close();
    size?.close();
    weight.close();
  }
}