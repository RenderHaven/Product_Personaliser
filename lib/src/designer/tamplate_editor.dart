import 'package:flutter/material.dart';
import '../../product_personaliser.dart';
import '../designer/product_designer.dart';
import '../models/design_templates.dart';
import 'dart:html' as html;
import 'create_template.dart';

class TemplateEditor extends StatefulWidget {
  final DesignTemplate? initialTemplate;
  final Future<void> Function()? onSave;
  const TemplateEditor({super.key, this.initialTemplate, this.onSave});

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  late DesignTemplate template;
  late DesignPage currentPage;
  ElementArea? selectedArea;
  bool isSaving = false;

  Future<void> _uploadImage() async {
    final uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false; // allow only one image

    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      final file = files.first;

      const int maxSizeInBytes = 2 * 1024 * 1024; // 1 MB

      if (file.size > maxSizeInBytes) {
        // You can use a snackbar, dialog, or other UI warning here
        print('File too large. Max size is 2MB.');
        return;
      }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) {
        final base64Image = reader.result;
        if (base64Image != null && base64Image is String) {
          setState(() {
            currentPage.bgImageUrl = base64Image;
          });
        }
      });
    });
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text), // Submit
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<List<String>?> _showPageRenameDialog(
    BuildContext context,
    String currentName,
    String currentPrice,
    String? currentGroup,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final priceController = TextEditingController(text: currentPrice);
    final colorGroupController = TextEditingController(text: currentGroup);
    Color? currentColor;

    // Convert hex to color safely

    // Initialize color
    currentColor = Tools.tryParseColor(currentGroup);
    return showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rename'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'New Name'),
                    autofocus: true,
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'New Price'),
                  ),
                  TextField(
                    controller: colorGroupController,
                    decoration: InputDecoration(
                      labelText: 'New Color Group (Hex)',
                      suffixIcon: currentColor != null
                          ? Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentColor,
                                border: Border.all(color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.error, color: Colors.red),
                    ),
                    onChanged: (val) {
                      setState(() {
                        currentColor = Tools.tryParseColor(val);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pick a color:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          "#FF0000",
                          "#00FF00",
                          "#0000FF",
                          "#FFFF00",
                          "#FFA500",
                          "#800080",
                          "#000000",
                          "#FFFFFF",
                        ].map((hex) {
                          return GestureDetector(
                            onTap: () {
                              colorGroupController.text = hex;
                              setState(() {
                                currentColor = Tools.tryParseColor(hex);
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Tools.tryParseColor(hex),
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (currentColor != null) {
                    Navigator.pop(context, [
                      nameController.text,
                      priceController.text,
                      colorGroupController.text,
                    ]);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addNewPage() {
    final newPage = DesignPage(
      // id: 'page_${template.pages.length + 1}',
      name: 'Page ${template.pages.length + 1}',
      elementAreas: [],
    );

    setState(() {
      template.pages.add(newPage);
      currentPage = newPage;
    });
    _addNewArea();
  }

  void _addNewArea() {
    final newArea = ElementArea(
      id: 'area_${currentPage.elementAreas.length + 1}',
      x: 100,
      y: 100,
      width: 200,
      height: 100,
    );

    setState(() {
      currentPage.elementAreas.add(newArea);
      selectedArea = newArea;
    });
  }

  @override
  void initState() {
    super.initState();
    template = widget.initialTemplate ?? CreateTemplate.defaultTemplate();
    currentPage = template.pages.isNotEmpty
        ? template.pages.first
        : DesignPage(name: "Dummy", elementAreas: []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: templateEditorAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final page in template.pages)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 5,
                                  children: [
                                    Text(page.name),
                                    if (page.group != null)
                                      CircleAvatar(
                                        backgroundColor: Tools.tryParseColor(
                                          page.group,
                                        ),
                                        radius: 10,
                                      ),
                                  ],
                                ),
                                Text(
                                  "${page.price} rs",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            selected: page == currentPage,
                            onSelected: (_) async {
                              if (currentPage == page) {
                                final newName = await _showPageRenameDialog(
                                  context,
                                  page.name,
                                  page.price,
                                  page.group,
                                );
                                if (newName != null && newName.length == 3) {
                                  setState(() {
                                    page.name = newName[0];
                                    page.price = newName[1];
                                    page.group = newName[2];
                                  });
                                }
                              } else
                                setState(() => currentPage = page);
                            },
                            selectedColor: Colors.blue.shade100,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),

                      // Add Page Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 4),
                              Text('Add Page'),
                            ],
                          ),
                          onPressed: _addNewPage,
                          backgroundColor: Colors.green.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
                MasterActions(),
                Center(
                  child: Container(
                    height: 500,
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      image: DecorationImage(
                        image: NetworkImage(currentPage.bgImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: currentPage.elementAreas.map((area) {
                        final isSelected = selectedArea == area;

                        return _buildControllerBox(
                          area: area,
                          isSelected: isSelected,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(
                  height: 80,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ...currentPage.elementAreas.map((a) {
                          final isSelected = a == selectedArea;
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                child: ChoiceChip(
                                  showCheckmark: false,
                                  label: Text("Area ${a.id}"),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      setState(() => selectedArea = a),
                                  selectedColor: Colors.blue.shade200,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentPage.elementAreas.remove(a);
                                    });
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.fromBorderSide(
                                        BorderSide(color: Colors.blue),
                                      ),
                                    ),
                                    child: const Text(
                                      '✕',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        // Add Area Chip
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 4),
                                Text('Add Area'),
                              ],
                            ),
                            onPressed: _addNewArea,
                            backgroundColor: Colors.green.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControllerBox({
    bool isSelected = false,
    required ElementArea area,
  }) {
    return Positioned(
      left: area.x,
      top: area.y,
      width: area.width,
      height: area.height,
      child: Stack(
        children: [
          PanBlocker(
            onTap: () => setState(() => selectedArea = area),
            onPanUpdate: (d) {
              if (selectedArea != area) return;
              setState(() {
                area.x += d.delta.dx;
                area.y += d.delta.dy;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // Resize handles
          if (isSelected) ..._buildResizeHandles(area),
        ],
      ),
    );
  }

  List<Widget> _buildResizeHandles(ElementArea area) {
    Widget box = Container(
      height: 15,
      width: 15,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
    );
    return [
      // Bottom-right handle
      Positioned(
        right: 0,
        bottom: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            setState(() {
              area.width += d.delta.dx;
              area.height += d.delta.dy;
            });
          },
          child: box,
        ),
      ),
      // Bottom-left handle
      Positioned(
        left: 0,
        bottom: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            setState(() {
              area.x += d.delta.dx;
              area.width -= d.delta.dx;
              area.height += d.delta.dy;
            });
          },
          child: box,
        ),
      ),
      // Top-right handle
      Positioned(
        right: 0,
        top: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            setState(() {
              area.y += d.delta.dy;
              area.height -= d.delta.dy;
              area.width += d.delta.dx;
            });
          },
          child: box,
        ),
      ),
      // Top-left handle
      Positioned(
        left: 0,
        top: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            setState(() {
              area.x += d.delta.dx;
              area.y += d.delta.dy;
              area.width -= d.delta.dx;
              area.height -= d.delta.dy;
            });
          },
          child: box,
        ),
      ),
    ];
  }

  Widget MasterActions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => _uploadImage(),
            icon: const Icon(Icons.image, color: Colors.blue),
            label: const Text(
              'Background',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                currentPage.elementAreas.clear();
                selectedArea = null;
              });
            },
            icon: const Icon(Icons.cleaning_services, color: Colors.orange),
            label: const Text('Clear', style: TextStyle(color: Colors.orange)),
          ),
          TextButton.icon(
            onPressed: () {
              if (template.pages.length > 1) {
                setState(() {
                  template.pages.remove(currentPage);
                  currentPage = template.pages.first;
                  selectedArea = null;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot delete the only page.')),
                );
              }
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget templateEditorAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: TextButton.icon(
        onPressed: () async {
          final newName = await _showRenameDialog(context, template.name);
          if (newName != null && newName.isNotEmpty) {
            setState(() {
              template.name = newName;
            });
          }
        },
        icon: const Icon(Icons.edit, color: Colors.black),
        label: Text(
          template.name,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            if (isSaving) return;
            if (widget.onSave != null) {
              setState(() {
                isSaving = true;
              });

              // showDialog(
              //   context: context,
              //   barrierDismissible: false,
              //   builder: (BuildContext context) {
              //     return const AlertDialog(
              //       content: Row(
              //         children: [
              //           CircularProgressIndicator(),
              //           SizedBox(width: 20),
              //           Text("Saving..."),
              //         ],
              //       ),
              //     );
              //   },
              // );

              // Slight delay to ensure dialog is rendered
              // Now perform the save
              await widget.onSave!();
              // Close the current screen
              Navigator.of(context).pop(); // Pops the TemplateEditor
            } else {
              Navigator.of(context).pop(); // If onSave is null, just close
            }
          },

          icon: const Icon(Icons.save, color: Colors.green),
          label: Text(
            isSaving ? 'Saving...' : 'Save',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }
}
