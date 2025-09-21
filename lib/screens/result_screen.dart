import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:docman/docman.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;

  const ResultScreen({super.key, required this.score, required this.total});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _fadeController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _fadeAnimation;
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.score / widget.total * 100,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scoreController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

Future<void> _saveResult() async {
  setState(() => _isSaving = true);

  try {
    // build the text content
    final percentage = (widget.score / widget.total * 100).toStringAsFixed(2);
    final now = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    final content =
        "Quiz Result\n${'-' * 30}\nScore: ${widget.score} / ${widget.total}\nPercentage: $percentage%\nDate: $now\n${'-' * 30}\n";

    final prefs = await SharedPreferences.getInstance();
    final savedDirUri = prefs.getString('dreamless_dir_uri');

    DocumentFile? baseDir;

    // If we already have a saved URI, try to use it directly
    if (savedDirUri != null) {
      try {
        baseDir = await DocumentFile.fromUri(savedDirUri);
        // Test if we can actually use it by checking if it exists
        if (!(await baseDir!.exists)) {
          throw Exception('Directory no longer exists');
        }
      } catch (e) {
        // If we can't use the saved URI, clear it and ask for a new one
        baseDir = null;
        await prefs.remove('dreamless_dir_uri');
      }
    }

    // If we don't have a valid baseDir, ask the user to pick one
    if (baseDir == null) {
      final picked = await DocMan.pick.directory();

      if (picked == null) {
        // user cancelled
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save cancelled. Please pick a folder to save into.')),
          );
        }
        return;
      }

      baseDir = picked;
      // save its URI for future silent saves
      await prefs.setString('dreamless_dir_uri', baseDir.uri);
    }

    // At this point baseDir is a directory the app may write into
    // Create / find the "Dreamless Dreams" subfolder
    DocumentFile? dreamDir = await baseDir.find('Dreamless Dreams');
    if (dreamDir == null) {
      dreamDir = await baseDir.createDirectory('Dreamless Dreams');
      if (dreamDir == null) {
        throw Exception('Failed to create "Dreamless Dreams" folder');
      }
    }

    // Create the text file inside Dreamless Dreams
    final filename = 'quiz_result_${DateTime.now().millisecondsSinceEpoch}.txt';
    final created = await dreamDir.createFile(name: filename, content: content);

    if (created == null) throw Exception('Failed to create file');

    // feedback to user
    HapticFeedback.mediumImpact();

    setState(() {
      _isSaving = false;
      _saved = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Result saved to Documents/Dreamless Dreams ($filename)'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    // reset saved indicator after a moment
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _saved = false);
    });
  } catch (e) {
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

  String _getPerformanceEmoji() {
    final percentage = widget.score / widget.total * 100;
    if (percentage >= 90) return '🏆';
    if (percentage >= 75) return '🌟';
    if (percentage >= 60) return '👍';
    if (percentage >= 40) return '💪';
    return '📚';
  }

  String _getPerformanceMessage() {
    final percentage = widget.score / widget.total * 100;
    if (percentage >= 90) return 'Outstanding!';
    if (percentage >= 75) return 'Great Job!';
    if (percentage >= 60) return 'Good Work!';
    if (percentage >= 40) return 'Keep Practicing!';
    return 'Don\'t Give Up!';
  }

  Color _getScoreColor() {
    final percentage = widget.score / widget.total * 100;
    if (percentage >= 90) return Colors.green.shade400;
    if (percentage >= 75) return Colors.lightGreen.shade400;
    if (percentage >= 60) return Colors.yellow.shade600;
    if (percentage >= 40) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.total * 100).toStringAsFixed(1);
    final scoreColor = _getScoreColor();

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade400,
          secondary: Colors.purple.shade400,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0E21),
                const Color(0xFF1A1F3A),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Performance Emoji
                        Text(
                          _getPerformanceEmoji(),
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 20),
                        
                        // Performance Message
                        Text(
                          _getPerformanceMessage(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: scoreColor.withOpacity(0.5),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Score Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: scoreColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scoreColor.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Animated Percentage
                              AnimatedBuilder(
                                animation: _scoreAnimation,
                                builder: (context, child) {
                                  return Column(
                                    children: [
                                      Text(
                                        '${_scoreAnimation.value.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.w900,
                                          color: scoreColor,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Progress Bar
                                      Container(
                                        height: 12,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 200 * (_scoreAnimation.value / 100),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    scoreColor,
                                                    scoreColor.withOpacity(0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: scoreColor.withOpacity(0.5),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Score Details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildScoreDetail('Correct', widget.score.toString(), Colors.green.shade400),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Colors.white.withOpacity(0.2),
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _buildScoreDetail('Total', widget.total.toString(), Colors.blue.shade400),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                onPressed: () => Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  (route) => false,
                                ),
                                icon: Icons.home_rounded,
                                label: 'Home',
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _isSaving ? null : _saveResult,
                                icon: _saved ? Icons.check_circle : Icons.save_alt_rounded,
                                label: _isSaving ? 'Saving...' : (_saved ? 'Saved' : 'Save'),
                                isPrimary: false,
                                isLoading: _isSaving,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    final color = isPrimary ? Colors.blue.shade400 : Colors.purple.shade400;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPrimary
                  ? [color, color.withOpacity(0.8)]
                  : [Colors.transparent, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? Colors.transparent : color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : color,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}