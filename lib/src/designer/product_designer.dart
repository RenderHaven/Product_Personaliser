import 'dart:convert';
import 'dart:ui' as ui;
import 'package:get/state_manager.dart';
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
  final Function(Uint8List? data,String? note, double finalPrice)? onNext;
  const ProductDesigner({super.key, required this.template, this.onNext});

  @override
  State<ProductDesigner> createState() => _ProductDesignerState();
}

class _ProductDesignerState extends State<ProductDesigner> {
  late DesignTemplate template;
  final RxList<DesignPage> finalpages = <DesignPage>[].obs;
  final RxList<DesignPage> finalselectedpages = <DesignPage>[].obs;
  String specialNote = '';
  final Set<String> groups = {};
  final RxString selectedgroup = ''.obs;
  final RxInt _currentStep = 1.obs;
  final RxBool isPreview = false.obs;
  final RxBool isZip = false.obs;

  final selectedArea = Rx<ElementArea?>(null);
  final selectedDesign = Rx<DesignElement?>(null);
  final currentPage = Rx<DesignPage?>(null);

  @override
  void initState() {
    super.initState();
    template = widget.template;
    template.pages.forEach((x) {
      if (x.group != null) groups.add(x.group!);
    });
    if (groups.length <= 1) {
      if (groups.isNotEmpty) selectedgroup.value = groups.first;
      _currentStep.value = 2;
    }
    _changeStep(2);
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalise Design'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Obx((){
            return Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Step indicator
                          stepIndicator(),
                          const SizedBox(height: 10),
                          
                          // Main content area
                          if (_currentStep.value == 1) _buildColorSelector(groups),
                          if (_currentStep.value != 1) ConstrainedBox(constraints: BoxConstraints(maxWidth: 1000), child: _buildMainBody(context)),
                          
                          // Action buttons
                          
                        ],
                      ),
                    ),
                  ),
                  _buildActionWidget(),
                ],
              ),
            );
          }),
          
          if (isZip.value)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: AlertDialog(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
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

  Widget stepIndicator() {
    Widget buildStepCircle(int step, bool isCompleted, bool isCurrent) {
      return InkWell(
        onTap: () => setState(() {
          _changeStep(step);
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
        ],
      ),
    );
  }

  Widget _buildColorSelector(Set<String> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            "Select Color",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Wrap(
          // shrinkWrap: true,
          // padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          spacing: 4,
          runSpacing: 4,
          children: [
            ...groups.map((group) {
              final color = Tools.tryParseColor(group) ?? Colors.transparent;
              final isSelected = group == selectedgroup.value;
    
              return GestureDetector(
                onTap: () {
                  selectedgroup.value = group;
                  selectedgroup.refresh();
                },
                child: Stack(
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border:Border.all(color:isSelected? Colors.blue:Colors.black, width: 2)
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
    );
  }

  Widget _buildMainBody(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isSmallScreen = constraints.maxWidth < 700;

      return Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(maxHeight: 500),
        child:isSmallScreen?
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
          ),
          child: ProductBody(),
        ):
        Center(
          child: Row(
            spacing: 5,
            children: [
              // Left side: Product body (fixed width on large screens)
              
              ProductBody(),
              // Right side: Editor panel (only on large screens)
              
              Expanded(
                child: Obx(() {
                  
                  return (selectedArea.value != null && !isPreview.value)
                      ? AreaElementEditor(
                          areaList: selectedArea.value!.subElements,
                          width: selectedArea.value!.width.value,
                          height: selectedArea.value!.height.value,
                          selectedElement: selectedDesign,
                          bgColor:  Tools.tryParseColor(selectedgroup.value)??Colors.white,
                        )
                      : _buildEmpty();
                }),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildEmpty(){
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'No Area Selected',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please select an area to edit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

 
  Widget ProductBody() {
  return Obx(() {
    if (currentPage.value == null) return const Center(child: Text('No page selected'));
    
    return SizedBox(
      width: 400,
      child: Stack(
        children: [
          
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: OverflowBox(
              alignment: Alignment.topLeft,
               maxWidth: 400,
              maxHeight: 500,
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(0), // Prevents shifting
                child: RepaintBoundary(
                  key: currentPage.value!.repaintKey,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 500,
                      maxWidth: 400,
                      minHeight: 500,
                      minWidth: 400,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        
                        image: NetworkImage(currentPage.value!.bgImageUrl),
                        fit: BoxFit.cover,
                        
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: (){
                              selectedArea.value = null;
                              selectedDesign.value = null;
                            },
                          ),
                        ),
                        
                        ...currentPage.value!.elementAreas.map((area) => 
                          Positioned(
                            left: area.x.value,
                            top: area.y.value,
                            width: area.width.value,
                            height: area.height.value,
                            child: RepaintBoundary(
                              key: area.repaintKey,
                              child: GestureDetector(
                                onTap: () => selectedArea.value = area,
                                child: _buildArea(area, area == selectedArea.value)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(alignment: Alignment.topRight, child: Pages()),
        ],
      ),
    );
  });
}

  Widget _buildArea(ElementArea area, bool isSelected) {
  return Obx(() {
    return Container(
      width: area.width.value,
      height: area.height.value,
      decoration: BoxDecoration(
        border: Border.all(
          color: isPreview.value?Colors.transparent: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: area.subElements.map((element) =>(element.isActive.value ||isPreview.value)? DraggableResizableBox(
          key: ValueKey(element.id),
          x: element.x,
          y: element.y,
          isDesign: true,
          width: element.width,
          height: element.height,
          isSelected: !isPreview.value && element==selectedDesign.value,
          child: Tools.buildElementContent(element),
          onTap: (){
            selectedArea.value = area;
            selectedDesign.value=element;
          },
        ):SizedBox.shrink()).toList(),
      ),
    );
  });
}




  Widget _buildActionWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;
        final showEditorButton = isSmallScreen && _currentStep.value == 2 && !isPreview.value;

        return Container(
          height: showEditorButton ? 100 : 80, // Adjust height if showing extra button
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Obx((){
            return Column(
              children: [
                // Preview mode toggle
                if (isPreview.value) _buildEditorButton(
                  icon: Icons.visibility, label: "Exit Preview", color: Colors.grey,
                  onTap: ()=>isPreview.value=false,
                ),
                if(!showEditorButton && !isPreview.value && _currentStep.value>1)
                _buildEditorButton(
                  icon: Icons.visibility, label: "See Preview", color: Colors.green,
                  onTap: ()=>isPreview.value=true,
                ),
                
                // Open Editor button (only on small screens in step 2)
                if (showEditorButton && !isPreview.value)_buildOpenEditorButton(context),
                
                // Main action buttons (Save/Next)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      if (_currentStep.value >= 2)
                        Expanded(child: _buildSaveButton()),
                      Expanded(child: _buildNextButton()),
                    ],
                  ),
                ),
              ],
            );
          })
        );
      },
    );
  }

Widget _buildOpenEditorButton(BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        // Open Editor Button (3 parts)
        Expanded(
          flex: 3,
          child: _buildEditorButton(
            icon: Icons.edit,
            label: "Open Editor",
            color: Colors.blue,
            isRightButton: false,
            onTap: () {
              if (selectedArea.value != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: AreaElementEditor(
                      areaList: selectedArea.value!.subElements,
                      width: selectedArea.value!.width.value,
                      height: selectedArea.value!.height.value,
                      selectedElement: selectedDesign,
                      bgColor:  Tools.tryParseColor(selectedgroup.value)??Colors.white,
                      isSmall: true,
                    ),
                  ),
                );
              } else {
                Tools.showTopMessage(context, 'Select Design Area', color: Colors.red);
              }
            },
          ),
        ),
        
        // Preview Button (2 parts)
        Expanded(
          flex: 2,
          child: _buildEditorButton(
            icon: Icons.visibility,
            label: "Preview",
            color: Colors.green,
            isRightButton: true,
            onTap: () => isPreview.value = true,
          ),
        ),
      ],
    ),
  );
}

Widget _buildEditorButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
  bool? isRightButton,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius:isRightButton==null?BorderRadius.circular(8):
         isRightButton
            ? const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _buildSaveButton() {
  return InkWell(
    onTap: () async {
      _createZipAndDownload(context);
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
  );
}

Widget _buildNextButton() {
  return InkWell(
    onTap: () => _changeStep(_currentStep.value + 1),
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
  );
}

  

  Widget Pages() {
    return Obx(() => SizedBox(
      height: 50,
      child: Row(
        children: finalpages.map((page) {
          bool isSelected = page == currentPage.value;
          return Expanded(
            child: InkWell(
              onTap: () {
                currentPage.value = page;
                selectedArea.value = page.elementAreas.isNotEmpty 
                  ? page.elementAreas.first 
                  : null;
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Obx(() => Checkbox(
                      value: finalselectedpages.contains(page),
                      onChanged: (_) {
                        if (finalselectedpages.contains(page)) {
                          finalselectedpages.remove(page);
                        } else {
                          finalselectedpages.add(page);
                          Tools.showTopMessage(context,'Page Is Added To Final Pages');
                        }
                      },
                    )),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          page.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${page.price} ₹",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }

  void _changeStep(int index) async {
    if (index == 1) {
      if (groups.length <= 1) return;
      finalpages.clear();
      selectedgroup.value = '';
      _currentStep.value = 1;
    }
    
    if (index == 2) {
      if (groups.length <= 1) {
        if (groups.isNotEmpty) selectedgroup.value = groups.first;
      } else if (groups.length >= 2 && selectedgroup.value.isEmpty) {
        return;
      }
      
      _currentStep.value = 2;
      finalpages.assignAll(groups.isEmpty
          ? template.pages
          : template.pages.where((x) => x.group == selectedgroup.value).toList());
      
      currentPage.value = finalpages.isNotEmpty
          ? finalpages.first
          : null;
      
      selectedArea.value = currentPage.value?.elementAreas.isNotEmpty ?? false
          ? currentPage.value!.elementAreas.first
          : null;
      
      isPreview.value = false;
    }

    if (index == 3) {
      if (_currentStep.value != 2) return;
      _currentStep.value = 3;
      isPreview.value = true;
    }
    
    if (index >= 4) {
      // Handle step 4 logic

      final zipData=await _createZipAndDownload(context);
      final totalPrice = finalpages.fold<double>(
        0.0,
        (sum, page) => sum + (double.tryParse(page.price) ?? 0.0),
      );
      Navigator.pop(context, zipData);
      
      if (widget.onNext != null) widget.onNext!(zipData,specialNote, totalPrice);
    }
  }

  Future<bool> _showFinalSummary() async {
    if(finalselectedpages.isEmpty){
      Tools.showTopMessage(context, 'Select Pages',color: Colors.red);
      return false;
    }
    TextEditingController specialNoteController = TextEditingController();

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  double totalPrice = finalselectedpages.fold(
                    0,
                    (sum, page) => sum + (double.parse(page.price)),
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: specialNoteController,
                        maxLines: 1,
                        maxLength: 50,
                        decoration: InputDecoration(
                          labelText: 'Special Note',
                          border: OutlineInputBorder(),
                          hintText: 'Write any special instructions here...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Final Pages',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: finalselectedpages
                            .map((page) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        page.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${page.price} rs',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Total Customization Charge: ₹$totalPrice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            specialNote = specialNoteController.text.trim(); 
                            Navigator.pop(context, true);
                          },
                          child: Text('Done'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    return result == true;
  }


  // Future<void> _ensurePainted(GlobalKey key) async {
  //   final boundary =
  //       key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  //   if (boundary == null) return;
  //   int tries = 0;
  //   while (boundary.debugNeedsPaint && tries < 10) {
  //     await Future.delayed(const Duration(milliseconds: 100));
  //     tries++;
  //   }
  // }

  String colorToHex(Color? color) {
    if(color==null)return 'NA';
    return '#${color.value.toRadixString(16).padLeft(6, '0').substring(2)}';
  }

  Future<Uint8List?> capturePagesAndCreateZip(BuildContext context) async {
  if (finalselectedpages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No Page Selected")),
    );
    return null;
  }
  
  isZip.value = true;
  final archive = Archive();
  selectedArea.value = null;
  isPreview.value = true;

  // Create a single string buffer for all pages' info
  final StringBuffer infoFileContent = StringBuffer();
  infoFileContent.writeln('/// SPECIAL NOTE ///');
  infoFileContent.writeln(specialNote);
  infoFileContent.writeln('................................................');
  infoFileContent.writeln('This file contains details of all text elements in the design');
  infoFileContent.writeln('................................................\n');

  for (final p in finalselectedpages) {
    try {
      currentPage.value = p;
      final page = currentPage.value!;

      // Ensure frame is rendered
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 100));

      // Add page header to info file
      infoFileContent.writeln('${page.name} // Page ${finalselectedpages.indexOf(p) + 1} of ${finalselectedpages.length}');
      infoFileContent.writeln('................................................');
      infoFileContent.writeln('Total Areas: ${page.elementAreas.length}');
      infoFileContent.writeln('Created: ${DateTime.now().toString()}');
      infoFileContent.writeln('................................................\n');

      // Capture page preview
      final pageKey = page.repaintKey;
      if (pageKey.currentContext == null || 
          pageKey.currentContext!.findRenderObject() is! RenderRepaintBoundary) {
        debugPrint("⚠️ Skipping page ${page.name}: boundary not found.");
        continue;
      }

      final pageBoundary = pageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image pageImage = await pageBoundary.toImage(pixelRatio: 3);
      final pageByteData = await pageImage.toByteData(format: ui.ImageByteFormat.png);
      if (pageByteData == null) {
        debugPrint("❌ Page ${page.name} image byte data is null");
        continue;
      }
      final pagePngBytes = pageByteData.buffer.asUint8List();
      archive.addFile(
        ArchiveFile('${page.name}/page_preview.png', pagePngBytes.length, pagePngBytes),
      );
      debugPrint("✅ Captured page ${page.name} preview");

      // Capture areas and design elements
      for (int i = 0; i < page.elementAreas.length; i++) {
        final area = page.elementAreas[i];
        final areaKey = area.repaintKey;

        try {
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 50));

          // Capture area preview
          if (areaKey.currentContext == null || 
              areaKey.currentContext!.findRenderObject() is! RenderRepaintBoundary) {
            debugPrint("⚠️ Skipping area ${i+1} on page ${page.name}: boundary not found.");
            continue;
          }

          final areaBoundary = areaKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final ui.Image areaImage = await areaBoundary.toImage(pixelRatio: 5);
          final areaByteData = await areaImage.toByteData(format: ui.ImageByteFormat.png);
          if (areaByteData == null) {
            debugPrint("❌ Area ${i+1} on page ${page.name} byte data is null");
            continue;
          }
          final areaPngBytes = areaByteData.buffer.asUint8List();
          archive.addFile(
            ArchiveFile('${page.name}/area_${i+1}_preview.png', areaPngBytes.length, areaPngBytes),
          );
          debugPrint("✅ Captured area ${i+1} preview on ${page.name}");

          // Add area info to the text file
          infoFileContent.writeln('Area ${i+1}:');
          infoFileContent.writeln('├─ Position: (${area.x.value.toStringAsFixed(1)}, ${area.y.value.toStringAsFixed(1)})');
          infoFileContent.writeln('├─ Size: ${area.width.value.toStringAsFixed(1)} × ${area.height.value.toStringAsFixed(1)}');
          infoFileContent.writeln('└─ Elements: ${area.subElements.length}');

          // Capture original images from design elements and collect text info
          int textElementCount = 0;
          for (int j = 0; j < area.subElements.length; j++) {
            final element = area.subElements[j];
            
            // Record text element details
            if (element.type == ElementType.text) {
              textElementCount++;
              infoFileContent.writeln('   └─ Text Element $textElementCount:');
              infoFileContent.writeln('      ├─ Content: "${element.textWidget.value?.title}"');
              infoFileContent.writeln('      ├─ Font: ${element.textWidget.value?.font}, ${element.textWidget.value?.weight.value}pt');
              infoFileContent.writeln('      ├─ Color: #${colorToHex(element.textWidget.value?.color.value)}');
              infoFileContent.writeln('      ├─ Position: (${element.x.value.toStringAsFixed(1)}, ${element.x.value.toStringAsFixed(1)})');
              infoFileContent.writeln('      └─ Size: ${element.width.value.toStringAsFixed(1)} × ${element.height.value.toStringAsFixed(1)}\n');
            }
            
            if (element.type == ElementType.image && element.imageUrl != null) {
              try {
                if (element.imageUrl!.startsWith('data:image')) {
                  final base64String = element.imageUrl!.split(',').last;
                  final originalBytes = base64.decode(base64String);
                  archive.addFile(
                    ArchiveFile(
                      '${page.name}/area_${i+1}_element_${j+1}_original.png',
                      originalBytes.length,
                      originalBytes,
                    ),
                  );
                  debugPrint("✅ Added original image for element ${j+1} in area ${i+1}");
                } else if (element.imageUrl!.startsWith('http')) {
                  // Handle network images if needed
                }
              } catch (e) {
                debugPrint("❌ Error processing original image for element ${j+1} in area ${i+1}: $e");
              }
            }
          }
        } catch (e) {
          debugPrint("❌ Error capturing area ${i+1} of page ${page.name}: $e");
        }
      }
      
      // Add page separator in info file
      infoFileContent.writeln('\n................................................');
      infoFileContent.writeln('END OF ${page.name.toUpperCase()}');
      infoFileContent.writeln('................................................\n\n');

    } catch (e) {
      debugPrint("❌ Error capturing page ${p.name}: $e");
    }
  }

  // Add the single info.txt file to the root of the archive
  final infoBytes = utf8.encode(infoFileContent.toString());
  archive.addFile(
    ArchiveFile(
      'info.txt',
      infoBytes.length,
      Uint8List.fromList(infoBytes),
    ),
  );

  debugPrint("✅ Added info.txt to archive");

  isZip.value = false;

  if (archive.isEmpty) {
    debugPrint("⚠️ No data captured, returning null");
    return null;
  }

  final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
  return zipBytes;
}

Future<Uint8List?> _createZipAndDownload(BuildContext context) async {
  // Show final summary dialog and confirm user wants to proceed
  if (!await _showFinalSummary()) return null;

  // Show loading indicator
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Preparing download...'),
        ],
      ),
      duration: const Duration(minutes: 1),
    ),
  );

  try {
    // Capture pages and create zip
    final zipData = await capturePagesAndCreateZip(context);
    
    // Remove loading indicator
    scaffoldMessenger.hideCurrentSnackBar();

    if (zipData == null || zipData.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("No data available to download")),
      );
      return null;
    }

    // Prepare download in web environment
    if (kIsWeb) {
      final blob = html.Blob([Uint8List.fromList(zipData)], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);
      // final anchor = html.AnchorElement(href: url)
      //   ..setAttribute('download', 'design_pages_${DateTime.now().millisecondsSinceEpoch}.zip')
      //   ..click();
      html.Url.revokeObjectUrl(url);
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Download started successfully')),
      );
    } else {
      // Handle mobile/download for non-web platforms
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Download not supported on this platform')),
      );
    }

    return zipData; // Return the zip data to caller
  } catch (e) {
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Error generating download: ${e.toString()}')),
    );
    Tools.showTopMessage(context,"Something Went Wrong",color: Colors.red);

    debugPrint('Error in _createZipAndDownload: $e');
    return null;
  }
}

  
}