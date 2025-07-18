import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/design_elements.dart';

class AreaElementEditor extends StatefulWidget {
  final double areaWidth;
  final double areaHeight;
  final DesignElement element;
  final ValueChanged<DesignElement> onUpdate;
  final isActive;

  const AreaElementEditor({
    super.key,
    required this.areaWidth,
    required this.areaHeight,
    required this.element,
    required this.onUpdate,
    this.isActive = false,
  });

  @override
  State<AreaElementEditor> createState() => _AreaElementEditorState();
}

class _AreaElementEditorState extends State<AreaElementEditor> {
  late double localX;
  late double localY;
  late double localWidth;
  late double localHeight;

  @override
  void initState() {
    super.initState();
    localX = widget.element.x;
    localY = widget.element.y;
    localWidth = widget.element.width;
    localHeight = widget.element.height;
  }

  void _updateElement() {
    widget.onUpdate(widget.element);
  }

  @override
  Widget build(BuildContext context) {
    final double left = localX;
    final double top = localY;
    final double width = localWidth;
    final double height = localHeight;
    return Transform.translate(
      offset: Offset(left, top),
      child: GestureDetector(
        onPanUpdate: (details) {
          if (!widget.isActive) return;
          setState(() {
            localX += details.delta.dx;
            localY += details.delta.dy;

            // Clamp inside the area
            localX = localX.clamp(0.0, widget.areaWidth - localWidth);
            localY = localY.clamp(0.0, widget.areaHeight - localHeight);

            _updateElement();
          });
        },
        child: SizedBox(
          height: height,
          width: width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: height,
                width: width,
                constraints: BoxConstraints(maxHeight: height, maxWidth: width),
                decoration: BoxDecoration(
                  border: widget.isActive
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                  // color: Colors.green.withOpacity(0.15),
                ),
                child: _buildElementContent(),
              ),
              if (widget.isActive)
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      localWidth += details.delta.dx;
                      localHeight += details.delta.dy;

                      // Clamp resize inside the area
                      localWidth = localWidth.clamp(
                        10.0,
                        widget.areaWidth - localX,
                      );
                      localHeight = localHeight.clamp(
                        10.0,
                        widget.areaHeight - localY,
                      );
                      _updateElement();
                    });
                  },
                  child: Container(width: 10, color: Colors.white, height: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElementContent() {
    final textWidget = widget.element.textWidget!;
    switch (widget.element.type) {
      case ElementType.text:
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              textWidget?.title ?? 'NA',
              style: GoogleFonts.getFont(
                textWidget.font,
                color: textWidget.color,
                fontSize: 100,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case ElementType.image:
        final url = widget.element.imageUrl;
        if (url != null && url is String) {
          return Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        } else {
          return const Center(child: Text('No Image'));
        }
      default:
        return const SizedBox();
    }
  }
}
