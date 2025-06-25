import 'package:flutter/material.dart';
import 'filtered_business_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BusinessShortcuts extends StatelessWidget {
  const BusinessShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> shortcuts = [
      {
        'icon': Icons.restaurant,
        'label': localization.restaurant,
        'key': 'Restaurant'
      },
      {
        'icon': Icons.cut,
        'label': localization.hairdresser,
        'key': 'Hairdresser'
      },
      {'icon': Icons.local_bar, 'label': localization.bar, 'key': 'Bar'},
      {
        'icon': Icons.delivery_dining,
        'label': localization.delivery,
        'key': 'Delivery'
      },
      {'icon': Icons.local_cafe, 'label': localization.coffee, 'key': 'Coffee'},
      {
        'icon': Icons.shopping_cart,
        'label': localization.shopping,
        'key': 'Shopping'
      },
      {
        'icon': Icons.fitness_center,
        'label': localization.fitness,
        'key': 'Fitness'
      },
      {
        'icon': Icons.health_and_safety,
        'label': localization.health,
        'key': 'Health'
      },
      {'icon': Icons.spa, 'label': localization.beauty, 'key': 'Beauty'},
      {
        'icon': Icons.theater_comedy,
        'label': localization.entertainment,
        'key': 'Entertainment'
      },
      {'icon': Icons.more_horiz, 'label': 'others', 'key': 'Other'},
    ];

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: shortcuts.map((shortcut) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
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
                          category: shortcut['key'] as String,
                          isCustomCategory: shortcut['key'] == 'Other',
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
