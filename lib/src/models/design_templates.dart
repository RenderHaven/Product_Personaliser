import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'design_elements.dart';

class DesignTemplate {
  final String id;
  String name;
  final List<DesignPage> pages;

  DesignTemplate({required this.id, required this.name, required this.pages});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory DesignTemplate.fromJson(Map<String, dynamic> json) {
    return DesignTemplate(
      id: json['id'],
      name: json['name'],
      pages: (json['pages'] as List<dynamic>)
          .map((p) => DesignPage.fromJson(p))
          .toList(),
    );
  }

  /// ✅ Create template from minimal user-provided data
  factory DesignTemplate.fromData(Map<String, dynamic> data) {
    final String templateId = data['id'] ?? 'NA';
    final String name = data['name'] ?? 'Unnamed Template';

    final List<DesignPage> pages = [];

    final List<dynamic> pageList = data['pages'] ?? [];

    for (int pageIndex = 0; pageIndex < pageList.length; pageIndex++) {
      final pageData = pageList[pageIndex];
      final String pageName = pageData['name'] ?? 'Unnamed Page';
      final String bgImageUrl = pageData['bgImageUrl'] ?? '';
      final String price = pageData['price'] ?? '0';
      final group = pageData['group'];

      final List<ElementArea> elementAreas = [];
      final List<dynamic> areaList = pageData['elementAreas'] ?? [];

      for (int i = 0; i < areaList.length; i++) {
        final areaData = areaList[i];
        elementAreas.add(
          ElementArea(
            id: 'area_${i + 1}',
            x: (areaData['x'] ?? 0).toDouble(),
            y: (areaData['y'] ?? 0).toDouble(),
            width: (areaData['width'] ?? 100).toDouble(),
            height: (areaData['height'] ?? 100).toDouble(),
          ),
        );
      }

      pages.add(
        DesignPage(
          name: pageName,
          bgImageUrl: bgImageUrl,
          elementAreas: elementAreas,
          price: price,
          group: group,
        ),
      );
    }

    return DesignTemplate(id: templateId, name: name, pages: pages);
  }

  /// ✅ Return simplified structured data (excluding all IDs)
  Map<String, dynamic> toStructuredData() => {
    'name': name,
    'id': id,
    'pages': pages
        .map(
          (p) => {
            'name': p.name,
            'bgImageUrl': p.bgImageUrl,
            'price': p.price,
            'group': p.group,
            'elementAreas': p.elementAreas
                .map(
                  (e) => {
                    'x': e.x.value,
                    'y': e.y.value,
                    'width': e.width.value,
                    'height': e.height.value,
                  },
                )
                .toList(),
          },
        )
        .toList(),
  };
}

class DesignPage {
  // final String id;
  String name;
  String bgImageUrl;
  String price;
  String? group;
  final List<ElementArea> elementAreas;
  final GlobalKey repaintKey = GlobalKey();

  DesignPage({
    // required this.id,
    required this.name,
    this.bgImageUrl ="",
    required this.elementAreas,
    this.price = '0',
    this.group,
  });

  Map<String, dynamic> toJson() => {
    // 'id': id,
    'name': name,
    'bgImageUrl': bgImageUrl,
    'elementAreas': elementAreas.map((e) => e.toJson()).toList(),
  };

  factory DesignPage.fromJson(Map<String, dynamic> json) {
    return DesignPage(
      // id: json['id'],
      name: json['name'],
      bgImageUrl: json['bgImageUrl'] ?? '',
      elementAreas: (json['elementAreas'] as List<dynamic>)
          .map((e) => ElementArea.fromJson(e))
          .toList(),
    );
  }
}

class ElementArea {
  final String id;

  /// Reactive fields
  final RxDouble x;
  final RxDouble y;
  final RxDouble width;
  final RxDouble height;

  /// Reactive list of sub-elements
  final RxList<DesignElement> subElements = <DesignElement>[].obs;
  final GlobalKey repaintKey = GlobalKey();

  ElementArea({
    required this.id,
    required double x,
    required double y,
    required double width,
    required double height,
    List<DesignElement>? initialSubElements,
  })  : x = RxDouble(x),
        y = RxDouble(y),
        height = RxDouble(height),
        width = RxDouble(width) {
    if (initialSubElements != null) {
      subElements.addAll(initialSubElements);
    }
  }

  /// Add a sub-element
  void addSubElement(DesignElement element) {
    subElements.add(element);
  }

  /// Remove a sub-element
  bool removeSubElement(String elementId) {
    final element = getSubElement(elementId);
    if (element != null) {
      element.dispose(); // Dispose the element before removing
      return subElements.remove(element);
    }
    return false;
  }

  /// Get a sub-element by ID
  DesignElement? getSubElement(String elementId) {
    try {
      return subElements.firstWhere((element) => element.id == elementId);
    } catch (e) {
      return null;
    }
  }

  /// For serialization: Convert to non-reactive types
  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x.value,
        'y': y.value,
        'width': width.value,
        'height': height.value,
        'subElements': subElements.map((e) => e.toJson()).toList(),
      };

  /// Deserialize and wrap values in Rx types
  factory ElementArea.fromJson(Map<String, dynamic> json) {
    return ElementArea(
      id: json['id'],
      x: json['x']?.toDouble() ?? 0,
      y: json['y']?.toDouble() ?? 0,
      width: json['width']?.toDouble() ?? 100,
      height: json['height']?.toDouble() ?? 100,
      initialSubElements: (json['subElements'] as List<dynamic>?)
          ?.map((e) => DesignElement.fromJson(e))
          .toList(),
    );
  }

  /// Clean up all Rx observables when the area is no longer needed
  void dispose() {
    // Dispose all sub-elements first
    for (final element in subElements) {
      element.dispose();
    }
    subElements.close(); // Close the RxList
    
    // Dispose individual Rx properties
    x.close();
    y.close();
    width.close();
    height.close();
  }
}

