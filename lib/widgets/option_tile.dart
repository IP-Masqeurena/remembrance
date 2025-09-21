import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String optionText;
  final bool isCorrect;
  final bool isSelected;
  final bool answered;
  final VoidCallback onTap;

  const OptionTile({
    Key? key,
    required this.optionText,
    required this.isCorrect,
    required this.isSelected,
    required this.answered,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Decide states
    final bool isWrong = answered && isSelected && !isCorrect;
    final bool isRight = answered && isCorrect;

    // Colors — tweak to your taste
    final Color rightColor = Colors.greenAccent.shade400;
    final Color wrongColor = Colors.redAccent.shade200;
    final Color defaultBg = Colors.white.withOpacity(0.02);

    Color bgColor;
    Color textColor = Colors.white;
    Color borderColor; // Add a new color variable for the border

    if (isRight) {
      bgColor = rightColor;
      textColor = Colors.black;
      borderColor = rightColor; // Use the same color for the border when correct
    } else if (isWrong) {
      bgColor = wrongColor;
      textColor = Colors.black;
      borderColor = wrongColor; // Use the same color for the border when wrong
    } else {
      bgColor = defaultBg;
      textColor = Colors.white.withOpacity(0.9);
      borderColor = Colors.white.withOpacity(0.2); // A more visible white border
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: answered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0), // Use the new borderColor variable
            boxShadow: [
              if (isRight || isWrong)
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // optional check/cross icon
              if (answered && isRight)
                const Icon(Icons.check_circle, color: Colors.black)
              else if (answered && isWrong)
                const Icon(Icons.cancel, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}