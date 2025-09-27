import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remembrance/models/question.dart';
import 'package:remembrance/screens/result_screen.dart';
import 'package:remembrance/services/db_services.dart';
import 'package:remembrance/widgets/option_tile.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;

class QuizScreen extends StatefulWidget {
  final String mode;
  final List<Question> questions;
   final int? sessionId;
   final List<int>? questionIndices;

  const QuizScreen({
    super.key,
    required this.mode,
    required this.questions,
    this.sessionId,
    this.questionIndices,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String? selectedOption;
  late List<String> shuffledOptions;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    shuffledOptions = widget.questions[currentIndex].getShuffledOptions();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 🎵 Play correct sound
  Future<void> playCorrect() async {
    final bytes =
        await rootBundle.load('lib/assets/sounds/correct.mp3');
    final sound = bytes.buffer.asUint8List();
    await _audioPlayer.play(BytesSource(sound));
  }

  /// 🎵 Play incorrect sound
  Future<void> playIncorrect() async {
    final bytes =
        await rootBundle.load('lib/assets/sounds/incorrect.mp3');
    final sound = bytes.buffer.asUint8List();
    await _audioPlayer.play(BytesSource(sound));
  }

  Future<void> checkAnswer(String option) async {
    if (answered) return;

    HapticFeedback.selectionClick();

    setState(() {
      answered = true;
      selectedOption = option;
      if (option == widget.questions[currentIndex].correctAnswer) {
        score++;
      }
    });

    // 🎵 Play sound depending on correctness
    if (option == widget.questions[currentIndex].correctAnswer) {
      await playCorrect();
    } else {
      await playIncorrect();
    }
  }

  void nextQuestion() {
    if (!answered) {
      HapticFeedback.vibrate();
      return;
    }

    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        answered = false;
        selectedOption = null;
        shuffledOptions =
            widget.questions[currentIndex].getShuffledOptions();
      });

      _animController
        ..reset()
        ..forward();
    } else {
      endQuiz();
    }
  }

  void endQuiz() async {
    int? sessionIdToRecord = widget.sessionId;
    
    // If this is a new quiz (not a reattempt), create the session now
    if (widget.sessionId == null && widget.mode != 'endless') {
      try {
        final newSessionId = await DBService.instance.createSession(
          widget.mode, 
          widget.questionIndices ?? []
        );
        sessionIdToRecord = newSessionId;
      } catch (e) {
        print('Failed to create session: $e');
      }
    }

    // Record attempt only if we have a sessionId (not in endless mode)
    if (sessionIdToRecord != null) {
      try {
        await DBService.instance.recordAttempt(
          sessionIdToRecord, 
          score, 
          widget.questions.length
        );
      } catch (e) {
        print('Failed to record attempt: $e');
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResultScreen(score: score, total: widget.questions.length),
      ),
    );
  }

  void confirmEndQuiz() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("End Quiz?"),
        content: const Text(
            "Do you really want to end the quiz? Your current progress will be shown."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No")),
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
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          constraints: BoxConstraints(
            // Limit the question card to maximum 40% of screen height
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed header section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (question.options.isNotEmpty)
                      Text(
                        'Choose one answer',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65), fontSize: 13),
                      ),
                  ],
                ),
              ),
              // Scrollable question content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildFormattedQuestion(question.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new method to your _QuizScreenState class:
  Widget _buildFormattedQuestion(String text) {
    // Check if text contains <br> and </br> tags
    if (text.contains('<br>') && text.contains('</br>')) {
      RegExp regex = RegExp(r'<br>(.*?)</br>');
      List<Widget> widgets = [];
      int lastIndex = 0;
      
      // Find all matches of text between <br> and </br>
      Iterable<RegExpMatch> matches = regex.allMatches(text);
      
      for (RegExpMatch match in matches) {
        // Add text before the tag (if any)
        if (match.start > lastIndex) {
          String beforeText = text.substring(lastIndex, match.start).trim();
          if (beforeText.isNotEmpty) {
            widgets.add(
              Text(
                beforeText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            );
            widgets.add(const SizedBox(height: 12));
          }
        }
        
        // Add the formatted text (text between <br> and </br>)
        String formattedText = match.group(1)?.trim() ?? '';
        if (formattedText.isNotEmpty) {
          widgets.add(
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  formattedText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
          widgets.add(const SizedBox(height: 12));
        }
        
        lastIndex = match.end;
      }
      
      // Add remaining text after the last tag (if any)
      if (lastIndex < text.length) {
        String remainingText = text.substring(lastIndex).trim();
        if (remainingText.isNotEmpty) {
          widgets.add(
            Text(
              remainingText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
        }
      }
      
      // Remove the last SizedBox if it exists
      if (widgets.isNotEmpty && widgets.last is SizedBox) {
        widgets.removeLast();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    } else {
      // Regular question without <br></br> tags
      return Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }
  }

  Widget _buildOptions(BuildContext context, Question question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: List.generate(shuffledOptions.length, (i) {
          final option = shuffledOptions[i];
          final isCorrect = option == question.correctAnswer;
          final isSelected = option == selectedOption;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
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
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            _buildHeader(context),
            // Question card with limited height
            _buildQuestionCard(context, question),
            const SizedBox(height: 8),
            // Options section - takes remaining space
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
            // Bottom action bar
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.02))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      answered
                          ? (selectedOption ==
                                  question.correctAnswer
                              ? 'Correct ✅'
                              : 'Incorrect ❌')
                          : 'Select an answer',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: answered ? nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered
                          ? Colors.greenAccent[700]
                          : Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      currentIndex <
                              widget.questions.length - 1
                          ? 'Next'
                          : 'Finish',
                      style: TextStyle(
                          color: answered
                              ? Colors.black
                              : Colors.white70),
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