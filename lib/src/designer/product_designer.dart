import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import './tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/design_elements.dart';
import '../models/design_templates.dart';
import '../widgets/design_element.dart';
import 'package:archive/archive.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart'; // for kIsWeb

class ProductDesigner extends StatefulWidget {
  final DesignTemplate template;
  final Function(Uint8List? data, double finalPrice)? onNext;
  const ProductDesigner({super.key, required this.template, this.onNext});

  @override
  State<ProductDesigner> createState() => _ProductDesignerState();
}

class _ProductDesignerState extends State<ProductDesigner> {
  late DesignTemplate template;
  late DesignPage currentPage;
  List<DesignPage> finalpages = [];
  List<DesignPage> finalselectedpages = [];
  final Set<String> groups = {};
  String? selectedgroup;
  late ElementArea? selectedArea;
  int _currentStep = 1;
  bool isPreview = false;
  bool isZip = false;
  @override
  void initState() {
    super.initState();
    template = widget.template;
    template.pages.forEach((x) {
      print(x.group);
      if (x.group != null) groups.add(x.group!);
    });
    if (groups.length <= 1) {
      if (groups.isNotEmpty) selectedgroup = groups.first;
      _currentStep = 2;
    }
    _changePage(2);
  }

  void _changePage(index) async {
    if (index == 1) {
      if (groups.length <= 1) return;
      finalpages = [];
      selectedgroup = null;
      setState(() {
        _currentStep = 1;
      });
    }
    if (index == 2) {
      if (groups.length <= 1) {
        if (groups.isNotEmpty) selectedgroup = groups.first;
      } else if (groups.length >= 2 && selectedgroup == null) {
        return;
      }
      setState(() {
        _currentStep = 2;
        finalpages = (groups.isEmpty)
            ? template.pages
            : template.pages.where((x) {
                return x.group == selectedgroup;
              }).toList();
        currentPage = finalpages.isNotEmpty
            ? finalpages.first
            : DesignPage(name: 'NA', elementAreas: []);
        selectedArea = currentPage.elementAreas.isNotEmpty
            ? currentPage.elementAreas.first
            : null;
        isPreview = false;
      });
    }

    if (index == 3) {
      if (_currentStep != 2) return;
      setState(() {
        _currentStep = 3;
        isPreview = true;
      });
    }
    if (index >= 4) {
      if (!await _showFinalPages()) return;
      final zipData = await capturePagesAndCreateZip(context);
      if (zipData == null || zipData.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No data")));
        return;
      }
      final totalPrice = finalpages.fold<double>(
        0.0,
        (sum, page) => sum + (double.tryParse(page.price) ?? 0.0),
      );
      Navigator.pop(context, zipData);
      if (widget.onNext != null) await widget.onNext!(zipData, totalPrice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finalise Design')),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  stepIndicator(),
                  Expanded(child: SingleChildScrollView(child: body())),
                  actionWidget(),
                ],
              ),
            ),
          ),
          if (isZip)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text("Creating..."),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildColorSelector(Set<String> groups) {
    return SizedBox(
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(
              "Select Color",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          GridView(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            children: [
              ...groups.map((group) {
                final color = Tools.tryParseColor(group) ?? Colors.transparent;
                final isSelected = group == selectedgroup;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedgroup = group;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget body() {
    if (_currentStep == 1) {
      return buildColorSelector(groups);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: RepaintBoundary(
        key: currentPage.repaintKey,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 500,
            maxWidth: 400,
            minHeight: 500,
            minWidth: 400,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            image: DecorationImage(
              image: NetworkImage(currentPage.bgImageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
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
              Align(alignment: Alignment.topRight, child: Pages()),
              for (final area in currentPage.elementAreas)
                Positioned(
                  left: area.x,
                  top: area.y,
                  width: area.width,
                  height: area.height,
                  child: RepaintBoundary(
                    key: area.repaintKey,
                    child: Stack(
                      children: [
                        if (!isPreview)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedArea = area;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: area == selectedArea
                                      ? Colors.white
                                      : Colors.grey,
                                  width: area == selectedArea ? 1 : 0.5,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: area == selectedArea
                                        ? Colors.black
                                        : Colors.grey,
                                    style: BorderStyle.solid,
                                    width: area == selectedArea ? 1 : 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        if (area.subElement != null)
                          _buildControllerBox(
                            child: _buildElementContent(area.subElement!),
                            element: area.subElement!,
                            isSelected: selectedArea == area && !isPreview,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget actionWidget() {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          if (_currentStep == 2)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _toolButton(
                        Icons.text_fields,
                        "Add Text",
                        onPressed: () {
                          if (selectedArea == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Select an Area'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          Tools.showFontPickerPopup(
                            context: context,
                            textWidget: selectedArea?.subElement?.textWidget,
                            onConfirm: (textWidget) {
                              setState(() {
                                if (selectedArea?.subElement?.type ==
                                    ElementType.text) {
                                  selectedArea!.subElement!.textWidget =
                                      textWidget;
                                } else {
                                  _addText(
                                    selectedArea,
                                    textWidget: textWidget,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _toolButton(
                        Icons.upload_file,
                        "Upload",
                        onPressed: () =>
                            _showImageUploadBottomSheet(selectedArea),
                      ),
                    ),
                    Expanded(
                      child: _toolButton(
                        isPreview ? Icons.visibility : Icons.visibility_off,
                        "Preview",
                        onPressed: () {
                          setState(() {
                            if (!isPreview) selectedArea = null;
                            isPreview = !isPreview;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (_currentStep >= 2)
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        if (!await _showFinalPages()) return;

                        final zipBytes = await capturePagesAndCreateZip(
                          context,
                        );
                        if (zipBytes == null || zipBytes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No data")),
                          );
                          return;
                        }

                        final blob = html.Blob([
                          Uint8List.fromList(zipBytes),
                        ], 'application/zip');
                        final url = html.Url.createObjectUrlFromBlob(blob);
                        final anchor = html.AnchorElement(href: url)
                          ..setAttribute('download', 'design_pages.zip')
                          ..click();
                        html.Url.revokeObjectUrl(url);
                      },
                      child: Container(
                        height: double.infinity,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white),
                        child: const Text(
                          "SAVE",
                          style: TextStyle(
                            color: Color(0xFF309193),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: InkWell(
                    onTap: () => _changePage(_currentStep + 1),
                    child: Container(
                      height: double.infinity,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xFF309193)),
                      child: const Text(
                        "NEXT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(
    IconData icon,
    String label, {
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget Pages() {
    int index = finalpages.indexOf(currentPage);

    return SizedBox(
      width: 140,
      // height: 50,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                if (index == 0) return;
                setState(() {
                  currentPage = finalpages[index - 1];
                });
              },
              child: Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: index == 0 ? Colors.grey : Colors.black,
              ),
            ),
            SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPage.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${currentPage.price} ₹",
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6),
            InkWell(
              onTap: () {
                if (index == finalpages.length - 1) return;
                setState(() {
                  currentPage = finalpages[index + 1];
                });
              },
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: index == finalpages.length - 1
                    ? Colors.grey
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget Areas() {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...currentPage.elementAreas.map((a) {
                  final isSelected = a == selectedArea;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text("Area ${a.id}"),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => selectedArea = isSelected ? null : a),
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addText(ElementArea? area, {TextWidget? textWidget}) {
    if (area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an Area'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Optionally stop further execution
    }

    final element = DesignElement(
      id: DateTime.now().toString(),
      type: ElementType.text,
      x: 0.1, // relative within area
      y: 0.1,
      width: min(50, selectedArea?.width ?? 10),
      height: min(50, selectedArea?.height ?? 10),
      textWidget: textWidget,
    );

    setState(() {
      area.subElement = element;
    });
  }

  void _showImageUploadBottomSheet(ElementArea? area) {
    if (area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an Area'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Optionally stop further execution
    }
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
                            _uploadImage(area); // call the upload function
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

  Future<void> _uploadImage(ElementArea? area) async {
    if (area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an Area'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Optionally stop further execution
    }

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File too large. Max size is 3MB.")),
        );
        return;
      }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) {
        final base64Image = reader.result;
        if (base64Image != null && base64Image is String) {
          if (selectedArea?.subElement != null) {
            selectedArea!.subElement!.imageUrl = base64Image;
            selectedArea!.subElement!.type = ElementType.image;
            setState(() {});
            return;
          }
          final element = DesignElement(
            id: DateTime.now().toString(),
            type: ElementType.image,
            x: 0.1,
            y: 0.1,
            width: selectedArea?.width ?? 10,
            height: selectedArea?.height ?? 10,
            imageUrl: base64Image,
          );

          setState(() {
            area.subElement = element;
          });
        }
      });
    });
  }

  Widget _buildControllerBox({
    bool isSelected = false,
    required DesignElement element,
    Widget child = const SizedBox.expand(),
  }) {
    return Positioned(
      left: element.x,
      top: element.y,
      width: element.width,
      height: element.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PanBlocker(
            onPanUpdate: (d) {
              if (!isSelected) return;
              setState(() {
                element.x = (element.x + d.delta.dx).clamp(
                  0.0,
                  selectedArea!.width - 10,
                );
                element.y = (element.y + d.delta.dy).clamp(
                  0.0,
                  selectedArea!.height - 10,
                );
              });
            },
            onTap: () {
              setState(() {
                selectedArea = currentPage.elementAreas.firstWhere((a) {
                  return a.subElement == element;
                });
              });
            },

            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: InteractiveViewer(child: child),
            ),
          ),

          // Resize handles
          if (isSelected) ..._buildResizeHandles(element),
        ],
      ),
    );
  }

  List<Widget> _buildResizeHandles(DesignElement element) {
    Widget box = Container(
      height: 15,
      width: 15,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
    );
    return [
      // Bottom-right hand
      Positioned(
        top: -10,
        left: element.width / 2 - 12,
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedArea!.subElement = null;
            });
          },
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: Colors.blue)),
            ),
            child: Text('X'),
          ),
        ),
      ),
      Positioned(
        right: 0,
        bottom: 0,
        child: PanBlocker(
          onPanUpdate: (d) {
            setState(() {
              element.width += d.delta.dx;
              element.height += d.delta.dy;
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
              element.x += d.delta.dx;
              element.width -= d.delta.dx;
              element.height += d.delta.dy;
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
              element.y += d.delta.dy;
              element.height -= d.delta.dy;
              element.width += d.delta.dx;
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
              element.x += d.delta.dx;
              element.y += d.delta.dy;
              element.width -= d.delta.dx;
              element.height -= d.delta.dy;
            });
          },
          child: box,
        ),
      ),

      // Align(
      //   alignment:Alignment.center,
      //   child: PanBlocker(
      //     onPanUpdate: (d) {
      //         // if(!isSelected)return;
      //         setState(() {
      //           element.x = (element.x + d.delta.dx).clamp(0.0, selectedArea!.width-10);
      //           element.y = (element.y + d.delta.dy).clamp(0.0, selectedArea!.height-10);
      //         });
      //     },
      //     child: box,
      //   ),
      // ),
    ];
  }

  Widget _buildElementContent(DesignElement element) {
    switch (element.type) {
      case ElementType.text:
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: element.textWidget?.getText(),
          ),
        );
      case ElementType.image:
        final url = element.imageUrl;
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

  Future<bool> _showFinalPages() async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Final Pages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final page in finalpages)
                            ChoiceChip(
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(page.name),
                                  Text(
                                    "${page.price} rs",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              selected: finalselectedpages.contains(page),
                              onSelected: (_) {
                                setState(() {
                                  if (finalselectedpages.contains(page)) {
                                    finalselectedpages.remove(page);
                                  } else {
                                    finalselectedpages.add(page);
                                  }
                                });
                                setModalState(() {});
                              },
                              selectedColor: Colors.blue.shade100,
                              backgroundColor: Colors.grey.shade200,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true); // Return true
                        },
                        child: Text('Done'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result == true; // return true only if "Done" pressed
  }

  Future<void> _ensurePainted(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    int tries = 0;
    while (boundary.debugNeedsPaint && tries < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      tries++;
    }
  }

  Future<Uint8List?> capturePagesAndCreateZip(BuildContext context) async {
    if (finalselectedpages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No Page Selected")));
      return null;
    }
    setState(() {
      isZip = true;
    });

    final archive = Archive();
    selectedArea = null;
    isPreview = true;

    for (final p in finalselectedpages) {
      try {
        setState(() => currentPage = p);

        // Ensure frame is rendered
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 100));

        final pageKey = currentPage.repaintKey;

        if (pageKey.currentContext == null ||
            pageKey.currentContext!.findRenderObject()
                is! RenderRepaintBoundary) {
          debugPrint(
            "⚠️ Skipping page ${currentPage.name}: boundary not found.",
          );
          continue;
        }

        final boundary =
            pageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

        // final pixelRatio =
        //     kIsWeb ? html.window.devicePixelRatio : ui.window.devicePixelRatio;

        final ui.Image pageImage = await boundary.toImage(pixelRatio: 1);
        final byteData = await pageImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) {
          debugPrint("❌ Page ${currentPage.name} image byte data is null");
          continue;
        }
        final pngBytes = byteData.buffer.asUint8List();

        archive.addFile(
          ArchiveFile('${currentPage.name}.png', pngBytes.length, pngBytes),
        );
        debugPrint(
          "✅ Captured ${currentPage.name} with ${pngBytes.length} bytes",
        );

        int j = 0;
        for (final area in currentPage.elementAreas) {
          j++;
          final areaKey = area.repaintKey;

          try {
            await WidgetsBinding.instance.endOfFrame;
            await Future.delayed(const Duration(milliseconds: 50));

            if (areaKey.currentContext == null ||
                areaKey.currentContext!.findRenderObject()
                    is! RenderRepaintBoundary) {
              debugPrint(
                "⚠️ Skipping area  on page ${currentPage.name}: boundary not found.",
              );
              continue;
            }

            final areaBoundary =
                areaKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final ui.Image areaImage = await areaBoundary.toImage(
              pixelRatio: 3,
            );
            final areaByteData = await areaImage.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (areaByteData == null) {
              debugPrint(
                "❌ Area  on page ${currentPage.name} byte data is null",
              );
              continue;
            }

            final areaPngBytes = areaByteData.buffer.asUint8List();

            final fileName =
                '${currentPage.name}_area_$j(${area.subElement?.textWidget?.font ?? "noFont"}).png';
            archive.addFile(
              ArchiveFile(fileName, areaPngBytes.length, areaPngBytes),
            );
            debugPrint(
              "✅ Captured area $j on ${currentPage.name} (${areaPngBytes.length} bytes)",
            );
          } catch (e) {
            debugPrint(
              "❌ Error capturing area $j of page ${currentPage.name}: $e",
            );
          }
        }
      } catch (e) {
        debugPrint("❌ Error capturing page ${currentPage.name}: $e");
      }
    }

    setState(() {
      isZip = false;
    });

    if (archive.isEmpty) {
      debugPrint("⚠️ No data captured, returning null");
      return null;
    }

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

    return zipBytes;
  }

  Widget stepIndicator() {
    Widget buildStepCircle(int step, bool isCompleted, bool isCurrent) {
      return InkWell(
        onTap: () => setState(() {
          _changePage(step);
        }),
        child: CircleAvatar(
          radius: 15,
          backgroundColor: isCompleted ? Colors.green : Colors.white,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$step',
                  style: TextStyle(
                    color: isCurrent ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              buildStepCircle(1, _currentStep > 1, _currentStep == 1),
              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep > 1 ? Colors.green : Colors.grey.shade300,
                ),
              ),
              buildStepCircle(2, _currentStep > 2, _currentStep == 2),
              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep > 2 ? Colors.green : Colors.grey.shade300,
                ),
              ),
              buildStepCircle(3, false, _currentStep == 3),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Pick Color & Size", style: TextStyle(fontSize: 12)),
              Text("Finalise Design", style: TextStyle(fontSize: 12)),
              Text("Preview", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
