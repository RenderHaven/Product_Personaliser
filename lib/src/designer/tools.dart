import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/design_elements.dart';
import 'package:flutter/gestures.dart';

class Tools {
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
    required TextWidget? textWidget,
  }) async {
    String selectedFont = textWidget?.font ?? 'Roboto';
    String inputText = textWidget?.title ?? '';
    bool showFontList = false;
    bool showColorList = false;
    Color selectedColor = textWidget?.color ?? Colors.black;
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    inputText.isEmpty ? 'Preview Text' : inputText,
                    style: GoogleFonts.getFont(
                      selectedFont,
                      fontSize: 20,
                      color: selectedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Text Field
                  const SizedBox(height: 16),
                  Row(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => inputText = val),
                          maxLength: 50,
                          maxLines: 2,
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Tap to enter text',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            counterText: "Max. 50 Characters",
                          ),
                        ),
                      ),
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

                  // Apply Button
                  const SizedBox(height: 16),

                  // Tool Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _toolBox(
                        Icons.text_fields,
                        "Edit",
                        Colors.yellow,
                        bold: true,
                        onTap: () {
                          setState(() {
                            showFontList = false;
                            showColorList = false;
                          });
                        },
                      ),
                      _toolBox(
                        Icons.font_download,
                        "Font",
                        Colors.grey.shade300,
                        onTap: () {
                          setState(() {
                            showFontList = true;
                            showColorList = false;
                          });
                        },
                      ),
                      _toolBox(
                        Icons.color_lens,
                        "Color",
                        Colors.grey.shade300,
                        onTap: () {
                          setState(() {
                            showColorList = true;
                            showFontList = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Font Picker
                  if (showFontList)
                    SizedBox(
                      height: 100,
                      width: double.infinity,
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

                  // Color Picker
                  if (showColorList)
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
                  const SizedBox(height: 16),

                  // Preview
                ],
              );
            },
          ),
        );
      },
    );
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
