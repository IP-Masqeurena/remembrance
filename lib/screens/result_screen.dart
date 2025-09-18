import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;

  const ResultScreen({super.key, required this.score, required this.total});

  Future<void> saveResult() async {
    final percentage = (score / total * 100).toStringAsFixed(2);
    final now = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final content =
        "Result:\nScore: $score / $total\nPercentage: $percentage%\nDate: $now\n";

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/quiz_result_${DateTime.now().millisecondsSinceEpoch}.txt");
    await file.writeAsString(content);
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (score / total * 100).toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("You got $score out of $total correct"),
            Text("Percentage: $percentage%"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
              child: const Text("Return to Home"),
            ),
            ElevatedButton(
              onPressed: saveResult,
              child: const Text("Print Result"),
            ),
          ],
        ),
      ),
    );
  }
}
