import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:remembrance/models/data/questions.dart';
import 'package:remembrance/services/db_services.dart';
import 'quiz_screen.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _loadSessions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    final sessions = await DBService.instance.getAllSessions();
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
    _animationController.forward();
  }

  String _getModeName(String mode) {
    switch (mode) {
      case 'quick':
        return 'Quick Revision';
      case 'standard':
        return 'Standard Quiz';
      case 'endless':
        return 'Endless Mode';
      default:
        return mode.toUpperCase();
    }
  }

  List<Color> _getModeGradientColors(String mode) {
    switch (mode) {
      case 'quick':
        return [
          const Color.fromARGB(255, 135, 135, 10),
          const Color.fromARGB(255, 246, 255, 0),
        ];
      case 'standard':
        return [
          const Color(0xFF3F5EFB),
          const Color.fromARGB(255, 3, 247, 255),
        ];
      default:
        return [
          const Color.fromARGB(255, 37, 2, 2),
          const Color.fromARGB(255, 255, 0, 0),
        ];
    }
  }

  // Helper method to safely create opacity values
  double _safeOpacity(double opacity) {
    return opacity.clamp(0.0, 1.0);
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'quick':
        return Icons.bolt;
      case 'standard':
        return Icons.school;
      case 'endless':
        return Icons.all_inclusive;
      default:
        return Icons.quiz;
    }
  }

  Widget _buildSessionTile(Map<String, dynamic> session, int index) {
    final int id = session['id'] as int;
    final mode = session['mode'] as String;
    final createdAt = DateTime.parse(session['created_at'] as String);
    final best = session['best_score'] as int? ?? -1;
    final bestText = best >= 0 ? '$best' : 'No attempts';
    final dateText = DateFormat('MMM dd, yyyy • HH:mm').format(createdAt);
    final totalQuestions = (session['question_indices'] as List).length;
    final percentage = best >= 0 && totalQuestions > 0 ? ((best / totalQuestions) * 100).toStringAsFixed(1) : '0.0';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_safeOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(_safeOpacity(0.1)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_safeOpacity(0.3)),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _retakeSession(session),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Mode Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getModeGradientColors(mode)[0].withOpacity(_safeOpacity(0.8)),
                          _getModeGradientColors(mode)[1],
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getModeGradientColors(mode)[0].withOpacity(_safeOpacity(0.3)),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getModeIcon(mode),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Session Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getModeName(mode),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(_safeOpacity(0.7)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: best >= 0 ? Colors.green.withOpacity(_safeOpacity(0.2)) : Colors.grey.withOpacity(_safeOpacity(0.2)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: best >= 0 ? Colors.green.withOpacity(_safeOpacity(0.4)) : Colors.grey.withOpacity(_safeOpacity(0.4)),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Best: $bestText',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: best >= 0 ? Colors.green.shade300 : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (best >= 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getScoreColor(double.parse(percentage)).withOpacity(_safeOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getScoreColor(double.parse(percentage)).withOpacity(_safeOpacity(0.4)),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getScoreColor(double.parse(percentage)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_safeOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.replay,
                      color: Colors.white.withOpacity(_safeOpacity(0.8)),
                      size: 20,
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

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return Colors.green.shade400;
    if (percentage >= 75) return Colors.lightGreen.shade400;
    if (percentage >= 60) return Colors.yellow.shade600;
    if (percentage >= 40) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  void _retakeSession(Map<String, dynamic> session) async {
    HapticFeedback.lightImpact();
    
    final int id = session['id'] as int;
    final sessionData = await DBService.instance.getSession(id);
    if (sessionData == null) return;
    
    final indices = (sessionData['question_indices'] as List).cast<int>();
    final questions = indices.map((i) => allQuestions[i]).toList();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => QuizScreen(
          mode: sessionData['mode'] as String,
          questions: questions,
          sessionId: id,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_safeOpacity(0.05)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(_safeOpacity(0.2)),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.history,
                size: 64,
                color: Colors.white.withOpacity(_safeOpacity(0.6)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Memories Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(_safeOpacity(0.9)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some quizzes to see your history',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(_safeOpacity(0.6)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start a Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Memory of Fierce Struggles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_loading && _sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadSessions,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black.withOpacity(_safeOpacity(0.95)),
            ],
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : _sessions.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadSessions,
                    backgroundColor: Colors.grey.shade800,
                    color: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) => _buildSessionTile(_sessions[index], index),
                    ),
                  ),
      ),
    );
  }
}