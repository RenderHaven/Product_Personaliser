import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:product_personaliser/product_personaliser.dart';
import 'dart:html' as html;
class AreaElementEditor extends StatefulWidget {
  final RxList<DesignElement?> areaList;
  final double width;
  final double height;
  final Color bgColor;
  final Rx<DesignElement?> selectedElement;
  final bool isSmall;
  const AreaElementEditor({
    super.key,
    required this.areaList,
    required this.height,
    required this.width,
    required this.selectedElement,
    this.bgColor=Colors.white,
    this.isSmall=false
  });

  @override
  State<AreaElementEditor> createState() => _AreaElementEditorState();
}

class _AreaElementEditorState extends State<AreaElementEditor> {

  
  

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header remains the same
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Design Editor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                widget.isSmall?ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),

                      
                    ),
                    // minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: (){
                    if(widget.isSmall)Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
                ):SizedBox.shrink(),

              ],
            ),
          ),
          
          // Reactive content area
          Expanded(
            child: Obx(() => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Element Preview
                  _buildElementPreview(),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildElements(),
                  // Tools Section
                  Text(
                    'ADD ELEMENTS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildToolGrid(),
                  
                  if (widget.selectedElement.value != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (widget.selectedElement.value!=null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // minimumSize: const Size(double.infinity, 40),
                        ),
                        onPressed: () => _editText(widget.selectedElement.value!),
                        child: Text(widget.selectedElement.value!.type.value==ElementType.text?'Edit Text':'Change Image', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    // _buildElementProperties(),
                  ],
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }


  Widget _buildElementPreview() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Element Preview', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Container(
        height: 300,
        width: double.infinity,
        
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          // color: widget.bgColor
        ),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: (){
                    widget.selectedElement.value=null;
                  },
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate the scale to fit the entire content
                  final scale = _calculateFitScale(
                    containerWidth: constraints.maxWidth,
                    containerHeight: constraints.maxHeight,
                    contentWidth: widget.width,
                    contentHeight: widget.height,
                  );
              
                  return Center(
                    child: Transform.scale(
                      scale:scale ,
                      child: Container(
                        width: widget.width,
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: widget.bgColor,
                          border: Border.all(color: Colors.black26),
                        ),
                        child: Obx(() => Stack(
                          children: [
                            ...widget.areaList.map((element) => 
                              element!.isActive.value?DraggableResizableBox(
                                key: ValueKey(element!.id),
                                x: element.x,
                                y: element.y,
                                isDesign: true,
                                width: element.width,
                                height: element.height,
                                isSelected: element == widget.selectedElement.value,
                                child: Tools.buildElementContent(element),
                                onTap: () => widget.selectedElement.value = element,
                                scale: scale,
                              ):SizedBox.shrink(),
                            ),
                          ],
                        ),)
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 8),
      Text('Dimensions: ${widget.width.toInt()} × ${widget.height.toInt()}'),
    ],
  );
}

double _calculateFitScale({
  required double containerWidth,
  required double containerHeight,
  required double contentWidth,
  required double contentHeight,
}) {
  final widthRatio = containerWidth / contentWidth;
  final heightRatio = containerHeight / contentHeight;
  return min(widthRatio, heightRatio) * 0.8; // 80% to add padding
}

  void _editElement(DesignElement element){
    if(element.type.value==ElementType.text)_editText(element);
    else _uploadImage(element:element);
  }

  void _editText(DesignElement element) {
    Tools.showFontPickerPopup(
      context: context,
      textWidget: element.textWidget.value,
      onConfirm: (newTextWidget) {
        element.textWidget.value = newTextWidget;
      },
    );
  }

  void _removeElement(DesignElement element){
    if(widget.selectedElement.value==element)widget.selectedElement.value==null;
    widget.areaList.remove(element);
    
    element.dispose();
  } 

  // Other methods remain largely the same, just update selectedElement.value instead of selectedElement
  void _addText() {
    
    Tools.showFontPickerPopup(
      context: context,
      onConfirm: (textWidget) {
        widget.selectedElement.value = DesignElement(
          id: DateTime.now().toString(),
          type: ElementType.text,
          x: 0.1,
          y: 0.1,
          width: min(50, widget.width),
          height: min(50, widget.height),
          textWidget: textWidget,
        );
        widget.areaList.add(widget.selectedElement.value!);
      },
    );
  }

  Widget _buildElements() {
    return Obx(() => widget.areaList.isNotEmpty?Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.areaList.asMap().entries.map((entry) {
            final index = entry.key;
            final element = entry.value;
            final isSelected = element == widget.selectedElement.value;
            
            // Determine color based on element type
            final Color color;
            if (element?.type.value == ElementType.text) {
              color = Colors.blue[100]!;
            } else if (element?.type.value == ElementType.image) {
              color = Colors.purple[100]!;
            } else {
              color = Colors.green[100]!;
            }
            
            return _buildElementButton(
              label: element?.type.value==ElementType.text?element?.textWidget.value?.title.value??'Text ${index+1}':"Image ${index+1}", // Display 1-based index
              color: color,
              isSelected: isSelected,
              element: element!,
            );
          }).toList(),
        ),
        const Divider(),
        const SizedBox(height: 16),
      ],
    ):SizedBox.shrink());
  }
  Widget _buildToolGrid() {
    return Row(
      spacing: 5,
      children: [
        _buildToolButton(
          icon: Icons.text_fields,
          label: 'Add Text',
          color: Colors.blue[100]!,
          onTap: () => _addText(),
        ),
        _buildToolButton(
          icon: Icons.image,
          label: 'Add Image',
          color: Colors.purple[100]!,
          onTap: () => Tools.showImageUploadBottomSheet(context,()=>_uploadImage()),
        ),
      ],
    );
  }



  void _uploadImage({DesignElement? element}) {
    
    final uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false; // allow only one image

    uploadInput.click();
    
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;

      const int maxSizeInBytes = 3 * 1024 * 1024; // 1 MB

      if (file.size > maxSizeInBytes) {
        Tools.showTopMessage(context, "File too large. Max size is 3MB.",color: Colors.red);
        return;
      }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) {
        final base64Image = reader.result;
        if (base64Image != null && base64Image is String) {
         
          widget.selectedElement.value =element??DesignElement(
            id: DateTime.now().toString(),
            type: ElementType.image,
            x: 0.1,
            y: 0.1,
            width: min(50, widget.width),
            height: min(50, widget.height),
            imageUrl: base64Image
          );
          if(element==null)widget.areaList.add(widget.selectedElement.value);
          else{
            widget.selectedElement.value?.imageUrl?.value=base64Image;
          }
        }
      });
    });
  }

  Widget _buildToolButton({
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    isSelected=false
  }) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      
      color: color,
      child: Container(
        decoration: BoxDecoration(
          border: isSelected?Border.all():null,
          borderRadius: BorderRadius.circular(8)
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(icon!=null)Icon(icon, size: 24, color: Colors.black87),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElementButton({
  required String label,
  required Color color,
  required DesignElement element,
  bool isSelected = false,
}) {
  return Material(
    borderRadius: BorderRadius.circular(12),
    elevation: 2,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 160), // Set max width here
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
            ? Border.all(color: Colors.blue, width: 2)
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clickable area for selecting the element
            InkWell(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              onTap: () => widget.selectedElement.value = element,
              onDoubleTap: () => _editElement(element),
              child: Padding(
                padding: const EdgeInsets.all(8), // Reduced padding for more space
                child: SizedBox(
                  width: double.infinity, // Take all available width
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis, // Handle overflow
                      maxLines: 2, // Allow text to wrap to 2 lines
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Dedicated button bar with better spacing and visual feedback
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                color: color.withOpacity(0.8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4), // Tighter padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.delete,
                    onPressed: () => _removeElement(element),
                    tooltip: 'Delete',
                  ),
                  _buildActionButton(
                    icon: element.isActive.value ? Icons.visibility : Icons.visibility_off,
                    onPressed: () => element.isActive.value = !element.isActive.value,
                    tooltip: element.isActive.value ? 'Hide' : 'Show',
                  ),
                  _buildActionButton(
                    icon: Icons.edit,
                    onPressed: () => _editElement(element),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper widget for consistent action buttons
Widget _buildActionButton({
  required IconData icon,
  required VoidCallback onPressed,
  required String tooltip,
}) {
  return Tooltip(
    message: tooltip,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18), // Slightly smaller icons
      color: Colors.black87,
      splashRadius: 18, // Smaller splash radius
      padding: EdgeInsets.all(6), // Tighter padding
      constraints: BoxConstraints(minWidth: 32, minHeight: 32), // Smaller minimum size
    ),
  );
}
}