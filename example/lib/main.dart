import 'package:flutter/material.dart';
import "package:product_personaliser/product_personaliser.dart";
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:MyTemplates(),
    );
  }
}

class MyTemplates extends StatefulWidget {
  @override
  _MyTemplatesState createState() => _MyTemplatesState();
}

class _MyTemplatesState extends State<MyTemplates> {
  final TextEditingController _searchController = TextEditingController();
  String tag = '';
  
  // Local state for templates
  List<DesignTemplate> templateList = [];
  List<DesignTemplate> templateSearchList = [];
  bool isLoading = false;
  
  // Default test template
  static final testTemplate = CreateTemplate.defaultTemplate();

  @override
  void initState() {
    super.initState();
    // Initialize with the test template
    templateList = [testTemplate];
    templateSearchList = List.from(templateList);
  }

  void _filterTemplates() {
    if (tag.isEmpty) {
      setState(() {
        templateSearchList = List.from(templateList);
      });
    } else {
      setState(() {
        templateSearchList = templateList
            .where((t) => t.name.toLowerCase().contains(tag))
            .toList();
      });
    }
  }

  void _updateTemplate({DesignTemplate? template}) {
    final newTemplate = template ?? CreateTemplate.defaultTemplate();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditor(
          initialTemplate: newTemplate,
          onSave: () async{
            // Add the new template to our list
            setState(() {
              templateList.add(newTemplate);
              _filterTemplates();
            });
          },
        ),
      ),
    ).then((_) {
      _filterTemplates();
    });
  }

  Future<void> _deleteTemplate({required DesignTemplate template}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${template.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        templateList.remove(template);
        _filterTemplates();
      });
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Template deleted successfully'),
      //     behavior: SnackBarBehavior.floating,
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(10),
      //   ),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _updateTemplate,
      ),
      appBar: AppBar(
        title: Text(
          'My Templates(${templateSearchList.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : IconButton(
                  onPressed: () {
                    // Simulate refresh by resetting to the test template
                    setState(() {
                      templateList = [testTemplate];
                      templateSearchList = List.from(templateList);
                    });
                  },
                  icon: Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'Search Templates...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            tag = '';
                            _filterTemplates();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  tag = value.toLowerCase();
                  _filterTemplates();
                },
              ),
            ),
            SizedBox(height: 20),
            isLoading
                ? Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : templateSearchList.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tab_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                tag.isEmpty
                                    ? 'No templates available'
                                    : 'No templates found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (tag.isEmpty)
                                TextButton(
                                  onPressed: _updateTemplate,
                                  child: Text(
                                    'Create your first template',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.separated(
                          itemCount: templateSearchList.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final template = templateSearchList[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDesigner(
                                        template: template,
                                        onNext: (result, note, price) {
                                          print(result?.length);
                                          print(note);
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              template.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () => _updateTemplate(template: template),
                                                icon: Icon(Icons.edit, size: 20),
                                                color: Colors.blue,
                                                tooltip: 'Edit',
                                              ),
                                              IconButton(
                                                onPressed: () => _deleteTemplate(template: template),
                                                icon: Icon(Icons.delete, size: 20),
                                                color: Colors.red,
                                                tooltip: 'Delete',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildInfoChip(
                                            icon: Icons.insert_drive_file,
                                            text: '${template.pages.length} pages',
                                          ),
                                          SizedBox(width: 8),
                                          _buildInfoChip(
                                            icon: Icons.info_outline,
                                            text: 'ID: ${template.id ?? 'N/A'}',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Chip(
      labelPadding: EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: Colors.grey[100],
      avatar: Icon(icon, size: 16),
      label: Text(
        text,
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}
