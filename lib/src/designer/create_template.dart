import '../models/design_templates.dart';

class CreateTemplate {
  static final data = {
    "name": "Simple Template",
    "pages": [
      {
        "name": "Front",
        "bgImageUrl":
            'https://www.teez.in/cdn/shop/products/flutter-developer-T-Shier-For-Men_s-5_large.jpg?v=1587186607',
        "My T-Shirt Template"
            "elementAreas": [
          {"x": 10, "y": 20, "width": 100, "height": 50},
        ],
      },
    ],
  };

  static DesignTemplate defaultTemplate() {
    return DesignTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'My T-Shirt Template',
      pages: [
        DesignPage(
          // id: 'page_1',
          name: 'Front Side',
          elementAreas: [
            ElementArea(id: 'area_1', x: 50, y: 50, width: 100, height: 100),
          ],
        ),
      ],
    );
  }
}
