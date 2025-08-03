import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:product_personaliser/product_personaliser.dart';
import '../models/design_elements.dart';
import 'package:flutter/gestures.dart';

class Tools {

  static Widget buildElementContent(DesignElement element) {
    return Obx(() {
      switch (element.type.value) {
        case ElementType.text:
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: element.textWidget.value?.getText() ?? const SizedBox(),
            ),
          );
        case ElementType.image:
          final url = element.imageUrl?.value;
          if (url != null) {
            return Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          } else {
            return const Center(child: Text('No Image'));
          }
      }
    });
  }

  

  static void showImageUploadBottomSheet(BuildContext context,Function onNext) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (context) {
        bool agreed = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image, size: 40, color: Colors.black54),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload an image to place it on the product',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Max. size should be 3 MB',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: agreed,
                        onChanged: (value) {
                          setModalState(() => agreed = value ?? false);
                        },
                      ),
                      Expanded(
                        child: const Text.rich(
                          TextSpan(
                            text:
                                'Please ensure the image is of good quality and ',
                            children: [
                              TextSpan(
                                text: 'not blurry.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: agreed
                        ? () {
                            Navigator.pop(context);
                            onNext();
                            // _uploadImage(area); // call the upload function
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: agreed
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                    child: const Text(
                      'PROCEED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showTopMessage(BuildContext context, String message,{Color color=Colors.black}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Container(
      alignment:Alignment.topCenter,
      margin: EdgeInsets.only(top: 55),
      // right: MediaQuery.of(context).size.width * 0.3,
      child: GestureDetector(
        onTap: () => overlayEntry.remove(), // Tap to dismiss
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12), // Smooth rounded corners
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:color, // Light transparent white
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2), // Subtle border
                  width: 1,
                ),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-remove after 3 seconds
  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}

  static Color? tryParseColor(String? hex) {
    if (hex == null) return null;
    try {
      hex = hex.replaceAll("#", "");
      if (hex.length == 6) hex = "FF$hex";
      if (hex.length != 8) return null;
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  static Future<void> showFontPickerPopup({
  required BuildContext context,
  required void Function(TextWidget testWidget) onConfirm,
  TextWidget? textWidget,
}) async {
  String selectedFont = textWidget?.font.value ?? 'Roboto';
  String inputText = textWidget?.title.value ?? 'Aa';
  bool showFontList = false;
  bool showColorList = false;
  Color selectedColor = textWidget?.color.value ?? Colors.black;
  double fontSize = textWidget?.size?.value ?? 20.0;
  FontWeight fontWeight = textWidget?.weight.value ?? FontWeight.normal;
  
  final controller = TextEditingController(text: inputText);
  final List<String> googleFontNames = [
    'Roboto',
    'Lobster',
    'Oswald',
    'Pacifico',
    'Raleway',
    'Merriweather',
    'Dancing Script',
    'Poppins',
  ];

  final List<Color> colorOptions = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.teal,
    Colors.white,
  ];

  final List<FontWeight> fontWeightOptions = [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];

  Widget _toolBox(
    IconData icon,
    String label,
    Color bgColor, {
    bool bold = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  await showModalBottomSheet(
    showDragHandle: true,
  context: context,
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => inputText = val),
                        maxLength: 15,
                        maxLines: 1,
                        controller: controller,
                        style:  GoogleFonts.getFont(
                          selectedFont,
                          fontSize: fontSize,
                          // color: selectedColor,
                          fontWeight: fontWeight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tap to enter text',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          counterText: "Max. 15 Characters",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.all(30),
                      ),
                      onPressed: () {
                        onConfirm(
                          TextWidget(
                            title: inputText,
                            color: selectedColor,
                            font: selectedFont,
                            size: fontSize,
                            weight: fontWeight,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Color Options
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Text Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorOptions.map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Font Family:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: googleFontNames.length,
                        itemBuilder: (context, index) {
                          String font = googleFontNames[index];
                          bool isSelected = selectedFont == font;
                          return GestureDetector(
                            onTap: () => setState(() => selectedFont = font),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.teal.withOpacity(0.2)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.teal
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    inputText.isEmpty ? 'Aa' : inputText,
                                    style: GoogleFonts.getFont(
                                      font,
                                      color: selectedColor,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    font,
                                    style: GoogleFonts.getFont(
                                      font,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                
                
                // Font Size Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Font Size: ${fontSize.toStringAsFixed(0)}'),
                    Slider(
                      value: fontSize,
                      min: 10,
                      max: 50,
                      divisions: 40,
                      onChanged: (value) {
                        setState(() {
                          fontSize = value;
                        });
                      },
                    ),
                  ],
                ),
                
                // Font Weight Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Font Weight: ${_getFontWeightName(fontWeight)}'),
                    Slider(
                      value: fontWeight.index.toDouble(),
                      min: 0,
                      max: FontWeight.values.length - 1,
                      divisions: FontWeight.values.length - 1,
                      onChanged: (value) {
                        setState(() {
                          fontWeight = FontWeight.values[value.toInt()];
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Font Options
                
              ],
            ),
          );
        },
      ),
    );
  },
);
}

// Helper function to get font weight name
static String _getFontWeightName(FontWeight weight) {
  switch (weight) {
    case FontWeight.w100: return 'Thin';
    case FontWeight.w200: return 'Extra Light';
    case FontWeight.w300: return 'Light';
    case FontWeight.w400: return 'Normal';
    case FontWeight.w500: return 'Medium';
    case FontWeight.w600: return 'Semi Bold';
    case FontWeight.w700: return 'Bold';
    case FontWeight.w800: return 'Extra Bold';
    case FontWeight.w900: return 'Black';
    default: return 'Normal';
  }
}
}

class PanBlocker extends StatelessWidget {
  final Widget child;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function()? onTap;

  const PanBlocker({
    Key? key,
    required this.child,
    required this.onPanUpdate,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        AllowPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<AllowPanGestureRecognizer>(
              () => AllowPanGestureRecognizer(),
              (instance) {
                instance.onUpdate = onPanUpdate;
                instance.onTapDown = (d) => onTap?.call();
              },
            ),
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class AllowPanGestureRecognizer extends OneSequenceGestureRecognizer {
  GestureDragUpdateCallback? onUpdate;
  GestureTapDownCallback? onTapDown;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'allowPan';

  Offset? _lastPosition;

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (_lastPosition != null && onUpdate != null) {
        onUpdate!(
          DragUpdateDetails(
            delta: event.delta,
            globalPosition: event.position,
            localPosition: event.localPosition,
            sourceTimeStamp: event.timeStamp,
          ),
        );
      }
      _lastPosition = event.position;
    } else if (event is PointerDownEvent) {
      onTapDown?.call(TapDownDetails(globalPosition: event.position));
      _lastPosition = event.position;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}
}


class DraggableResizableBox extends StatelessWidget {
  final RxDouble x;
  final RxDouble y;
  final RxDouble width;
  final RxDouble height;
  final bool isSelected;
  final Widget? child;
  final VoidCallback? onTap;
  final void Function(Offset delta)? onPositionUpdate;
  final void Function(Offset delta)? onSizeUpdate;
  final bool isDesign;
  final double scale; // Changed from int to double for finer control

  const DraggableResizableBox({
    super.key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.child,
    this.onTap,
    this.onPositionUpdate,
    this.onSizeUpdate,
    this.isSelected = false,
    this.isDesign = false,
    this.scale = 1.0, // Default scale is 1.0 (no scaling)
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Positioned(
      left: x.value,
      top: y.value,
      width: width.value,
      height: height.value,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PanBlocker(
            onPanUpdate: (d) {
              if (!isSelected) return;
              // Apply inverse scaling to movement deltas
              x.value += d.delta.dx / scale;
              y.value += d.delta.dy / scale;
              onPositionUpdate?.call(Offset(d.delta.dx / scale, d.delta.dy / scale));
            },
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : isDesign ? Colors.transparent : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: child,
            ),
          ),
          if (isSelected) ..._buildResizeHandles(),
        ],
      ),
    ));
  }

  List<Widget> _buildResizeHandles() {
    final handleSize = max(6.0, 10.0 / scale); // Minimum size of 6, scaled inversely

    Widget handle = Container(
      height: handleSize,
      width: handleSize,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
    );

    return [
      // Bottom-right
      Positioned(
        right: 0,
        bottom: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            width.value += d.delta.dx / scale;
            height.value += d.delta.dy / scale;
            onSizeUpdate?.call(Offset(d.delta.dx / scale, d.delta.dy / scale));
          },
          child: handle,
        ),
      ),
      // Bottom-left
      Positioned(
        left: 0,
        bottom: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            x.value += d.delta.dx / scale;
            width.value -= d.delta.dx / scale;
            height.value += d.delta.dy / scale;
            onSizeUpdate?.call(Offset(d.delta.dx / scale, d.delta.dy / scale));
          },
          child: handle,
        ),
      ),
      // Top-right
      Positioned(
        right: 0,
        top: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            y.value += d.delta.dy / scale;
            height.value -= d.delta.dy / scale;
            width.value += d.delta.dx / scale;
            onSizeUpdate?.call(Offset(d.delta.dx / scale, d.delta.dy / scale));
          },
          child: handle,
        ),
      ),
      // Top-left
      Positioned(
        left: 0,
        top: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            x.value += d.delta.dx / scale;
            y.value += d.delta.dy / scale;
            width.value -= d.delta.dx / scale;
            height.value -= d.delta.dy / scale;
            onSizeUpdate?.call(Offset(d.delta.dx / scale, d.delta.dy / scale));
          },
          child: handle,
        ),
      ),
    ];
  }
}


