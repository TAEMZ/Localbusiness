import 'package:flutter/material.dart';
import 'filtered_business_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BusinessShortcuts extends StatelessWidget {
  const BusinessShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> shortcuts = [
      {'icon': Icons.restaurant, 'label': localization.restaurant},
      {'icon': Icons.cut, 'label': localization.hairdresser},
      {'icon': Icons.local_bar, 'label': localization.bar},
      {'icon': Icons.delivery_dining, 'label': localization.delivery},
      {'icon': Icons.local_cafe, 'label': localization.coffee},
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
