import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remembrance/models/question.dart';
import 'package:remembrance/screens/result_screen.dart';
import 'package:remembrance/widgets/option_tile.dart';

class QuizScreen extends StatefulWidget {
  final String mode;
  final List<Question> questions;

  const QuizScreen({
    super.key,
    required this.mode,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String? selectedOption;
  late List<String> shuffledOptions;

  // Animation controller for entry animations
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // initial shuffle
    shuffledOptions = widget.questions[currentIndex].getShuffledOptions();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // play intro animation
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void checkAnswer(String option) {
    if (answered) return;

    HapticFeedback.selectionClick();

    setState(() {
      answered = true;
      selectedOption = option;
      if (option == widget.questions[currentIndex].correctAnswer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (!answered) {
      // optionally, you can provide a small hint that user must answer before proceed
      HapticFeedback.vibrate();
      return;
    }

    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        answered = false;
        selectedOption = null;
        shuffledOptions = widget.questions[currentIndex].getShuffledOptions();
      });

      // replay the small entry animation for the new question
      _animController
        ..reset()
        ..forward();
    } else {
      endQuiz();
    }
  }

  void endQuiz() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(score: score, total: widget.questions.length),
      ),
    );
  }

  void confirmEndQuiz() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("End Quiz?"),
        content: const Text("Do you really want to end the quiz? Your current progress will be shown."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              endQuiz();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final total = widget.questions.length;
    final progress = (currentIndex + 1) / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          // progress text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${currentIndex + 1} / $total',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: Colors.greenAccent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: confirmEndQuiz,
            child: const Text(
              'End Quiz',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, Question question) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              if (question.options.length > 0)
                Text(
                  'Choose one answer',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, Question question) {
    // Show options with staggered entrance animations.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: List.generate(shuffledOptions.length, (i) {
          final option = shuffledOptions[i];
          // For OptionTile: provide isCorrect, isSelected, answered.
          final isCorrect = option == question.correctAnswer;
          final isSelected = option == selectedOption;

          // staggered animation delay
          final delayMs = 80 * i;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 12),
                  child: child,
                ),
              );
            },
            child: OptionTile(
              optionText: option,
              isCorrect: isCorrect,
              isSelected: isSelected,
              answered: answered,
              onTap: () => checkAnswer(option),
            ),
            // simple delayed start by using Future.microtask to start later
            onEnd: () {},
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            _buildHeader(context),

            // Question card
            _buildQuestionCard(context, question),

            const SizedBox(height: 6),

            // Options area (takes remaining space)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOptions(context, question),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom action row: Next button + small info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.02))),
              ),
              child: Row(
                children: [
                  // Answer summary
                  Expanded(
                    child: Text(
                      answered
                          ? (selectedOption == question.correctAnswer ? 'Correct ✅' : 'Incorrect ❌')
                          : 'Select an answer',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: answered ? nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered ? Colors.greenAccent[700] : Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      currentIndex < widget.questions.length - 1 ? 'Next' : 'Finish',
                      style: TextStyle(color: answered ? Colors.black : Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
