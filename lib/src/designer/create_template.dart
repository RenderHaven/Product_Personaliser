import '../models/design_templates.dart';

class CreateTemplate {
 

  static DesignTemplate defaultTemplate() {
    return DesignTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'My T-Shirt Template',
      pages: [
        DesignPage(
          name: 'Front Side',
          group: '#FFFFFF',
          bgImageUrl: 'https://www.teez.in/cdn/shop/products/flutter-developer-T-Shier-For-Men_s-5_large.jpg?v=1587186607',
          elementAreas: [
            ElementArea(id: 'area_1', x: 150, y: 250, width: 100, height: 100),
          ],
        ),
      ],
    );
  }
}
