import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String optionText;
  final bool isCorrect;
  final bool isSelected;
  final bool answered;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.optionText,
    required this.isCorrect,
    required this.isSelected,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? tileColor;

    if (answered) {
      if (isCorrect) {
        tileColor = Colors.green;
      } else if (isSelected) {
        tileColor = Colors.red;
      }
    }

    return GestureDetector(
      onTap: !answered ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tileColor ?? Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          optionText,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
