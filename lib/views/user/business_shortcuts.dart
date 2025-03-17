import 'package:flutter/material.dart';
import 'filtered_business_page.dart';

class BusinessShortcuts extends StatelessWidget {
  const BusinessShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> shortcuts = [
      {'icon': Icons.restaurant, 'label': 'Restaurants'},
      {'icon': Icons.cut, 'label': 'Hairdresser'},
      {'icon': Icons.local_bar, 'label': 'Bars'},
      {'icon': Icons.delivery_dining, 'label': 'Delivery'},
      {'icon': Icons.local_cafe, 'label': 'Coffee'},
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: shortcuts.map((shortcut) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                shortcut['icon'] as IconData,
                size: 30.0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilteredBusinessPage(
                      category: shortcut['label'] as String,
                    ),
                  ),
                );
              },
            ),
            Text(
              shortcut['label'] as String,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
