import 'package:flutter/material.dart';
import '../../product_personaliser.dart';
import '../designer/product_designer.dart';
import '../models/design_templates.dart';
import 'dart:html' as html;
import 'create_template.dart';
import 'package:flutter/services.dart';

class TemplateEditor extends StatefulWidget {
  final DesignTemplate? initialTemplate;
  final Future<void> Function()? onSave;
  const TemplateEditor({super.key, this.initialTemplate, this.onSave});

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  late DesignTemplate template;
  late DesignPage? currentPage;
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
        Tools.showTopMessage(context,"File Should Be Small",color: Colors.red);
        return;
      }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) {
        final base64Image = reader.result;
        if (base64Image != null && base64Image is String) {
          setState(() {
            if(currentPage!=null)currentPage!.bgImageUrl = base64Image;
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
      id: 'area_${currentPage!.elementAreas.length + 1}',
      x: 100,
      y: 100,
      width: 200,
      height: 100,
    );

    setState(() {
      currentPage!.elementAreas.add(newArea);
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Center(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            children: [
              _buildPageSelectionRow(theme),
              SizedBox(height: 5,),
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    height: 500,
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      image: DecorationImage(
                        image: NetworkImage(currentPage?.bgImageUrl??''),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child:currentPage!=null? Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior
                              .translucent, // So taps pass through empty areas
                          onTap: () {
                            setState(() {
                              selectedArea = null; // or anything you want to do
                            });
                          },
                        ),
                      ),
                      Positioned(
                        left: 5,
                        top: 5,
                        child: Tooltip(
                          message: 'Change Background',
                          child: IconButton(
                            icon: Icon(Icons.image_outlined, size: 24),
                            color: theme.colorScheme.onSurface,
                            onPressed: _uploadImage,
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Tooltip(
                          message: 'Add Area',
                          child: IconButton(
                            icon: Icon(Icons.add, size: 24),
                            color: theme.colorScheme.onSurface,
                            onPressed: _addNewArea,
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: Tooltip(
                          message: 'Delete Page',
                          child: IconButton(
                            icon: Icon(Icons.delete, size: 24),
                            color: theme.colorScheme.onSurface,
                            onPressed:(){
                              if (template.pages.length > 1) {
                                setState(() {
                                  template.pages.remove(currentPage);
                                  currentPage = template.pages.first;
                                  selectedArea = null;
                                });
                              } else {
                                Tools.showTopMessage(context,'Cannot delete the only page.',color: Colors.red);
                              }
                            } ,
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ),
                      ...currentPage!.elementAreas.map((area) {
                      
                      return DraggableResizableBox(x: area.x, y: area.y, width: area.width, height: area.height, isSelected: selectedArea == area,
                        onTap: () => setState(() {
                          if(selectedArea!=area)selectedArea=area;
                        }),
                      );
                      // return _buildElementArea(
                      //   area,
                      //   isSelected,
                      // );
                    })],
                  ):Text('No Page'),
                  ),
                ),
              ),
              _buildElementAreasList(theme)
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final newName = await _showRenameDialog(context, template.name);
          if (newName != null && newName.isNotEmpty) {
            setState(() => template.name = newName);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                template.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: FilledButton.icon(
            onPressed: _saveTemplate,
            icon: isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 20),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSelectionRow(ThemeData theme) {
    return SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final page in template.pages)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  showCheckmark: false,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
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
      );
}

  Widget _buildElementAreasList(ThemeData theme) {
    return SizedBox(
      height: 72,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Text('Elements:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: currentPage!.elementAreas.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == currentPage!.elementAreas.length) {
                      return _buildAddAreaButton(theme);
                    }
                    final area = currentPage!.elementAreas[index];
                    return _buildAreaChip(area, theme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddAreaButton(ThemeData theme) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 18),
      label: const Text('Add Area'),
      onPressed: _addNewArea,
      backgroundColor: theme.colorScheme.surfaceVariant,
    );
  }

  Widget _buildAreaChip(ElementArea area, ThemeData theme) {
    final isSelected = selectedArea == area;
    return InputChip(
      label: Text('Area ${area.id.split('_').last}'),
      selected: isSelected,
      onPressed: () => setState(() => selectedArea = area),
      onDeleted: () {
        setState(() {
          currentPage!.elementAreas.remove(area);
          area.dispose();
          if (selectedArea == area) selectedArea = null;
        });
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surfaceVariant,
      labelStyle: TextStyle(
        color: isSelected 
            ? theme.colorScheme.onPrimaryContainer 
            : theme.colorScheme.onSurface,
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (isSaving) return;
    setState(() => isSaving = true);
    
    try {
      await widget.onSave?.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  // ... (keep all your existing dialog methods)
}