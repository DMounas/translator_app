// lib/widgets/language_selector.dart

import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final String labelText;
  final String selectedLanguageName;
  final Map<String, String> allLanguages;
  final Function(String) onLanguageSelected;

  const LanguageSelector({
    Key? key,
    required this.labelText,
    required this.selectedLanguageName,
    required this.allLanguages,
    required this.onLanguageSelected,
  }) : super(key: key);

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: ListView.builder(
            itemCount: allLanguages.length,
            itemBuilder: (context, index) {
              final langCode = allLanguages.keys.elementAt(index);
              final langName = allLanguages.values.elementAt(index);
              return ListTile(
                title: Text(langName),
                onTap: () {
                  onLanguageSelected(langCode);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showLanguagePicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // This Expanded + Text combination is guaranteed to prevent overflows
            Expanded(
              child: Text(
                selectedLanguageName,
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }
}