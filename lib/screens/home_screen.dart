import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remembrance/models/data/questions.dart';
import 'package:remembrance/screens/memory_screeen.dart';
import 'package:remembrance/services/db_services.dart';
import 'quiz_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

void _startQuiz(BuildContext context, String mode, {int? sessionId}) async {
  HapticFeedback.lightImpact();

  // If we are reattempting a session, load the session questions from DB:
  if (sessionId != null) {
    final session = await DBService.instance.getSession(sessionId);
    if (session == null) return;
    final List<int> indices = (session['question_indices'] as List).cast<int>();
    final questions = indices.map((i) => allQuestions[i]).toList();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => QuizScreen(
          mode: session['mode'] as String,
          questions: questions,
          sessionId: sessionId,
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
    return;
  }

  // Normal start (not reattempt)
  // Make a copy and shuffle so we don't alter global state unexpectedly
  final List questionsPool = List.from(allQuestions);
  questionsPool.shuffle();

  int questionCount;
  switch (mode) {
    case "quick":
      questionCount = 10;
      break;
    case "standard":
      questionCount = 40;
      break;
    default:
      questionCount = questionsPool.length;
  }

  final selectedQuestions = questionsPool.take(questionCount).toList();

  // Store indices of selected questions relative to allQuestions
  final indices = selectedQuestions.map<int>((q) => allQuestions.indexOf(q)).toList();
  
  // Don't create session here - pass the indices to QuizScreen and let it create the session
  // only when the quiz is actually completed
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => QuizScreen(
        mode: mode,
        questions: selectedQuestions.cast(),
        questionIndices: indices, // Pass indices instead of sessionId
        sessionId: null, // Will be created upon completion
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            color: Colors.black,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Header Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.psychology_alt_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Remembrance',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 8),
                      Text(
                        'Version: 2.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 60),
                
                // Quiz Mode Cards
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuizModeCard(
                            context: context,
                            mode: 'quick',
                            title: 'Quick Revision',
                            subtitle: '10 questions',
                            icon: Icons.bolt,
                            gradientColors: [
                              const Color.fromARGB(255, 135, 135, 10),
                              const Color.fromARGB(255, 246, 255, 0),
                            ],
                            delay: 0,
                          ),
                          const SizedBox(height: 10),
                          _buildQuizModeCard(
                            context: context,
                            mode: 'standard',
                            title: 'Standard Quiz',
                            subtitle: '40 questions',
                            icon: Icons.school,
                            gradientColors: [
                              const Color(0xFF3F5EFB),
                              const Color.fromARGB(255, 3, 247, 255),
                            ],
                            delay: 100,
                          ),
                          const SizedBox(height: 10),
                          _buildQuizModeCard(
                            context: context,
                            mode: 'endless',
                            title: 'Endless Mode',
                            subtitle: 'Non-stop questions',
                            icon: Icons.all_inclusive,
                            gradientColors: [
                              const Color.fromARGB(255, 37, 2, 2),
                              const Color.fromARGB(255, 255, 0, 0),
                            ],
                            delay: 200,
                          ),
                          const SizedBox(height: 10),
                          _buildQuizModeCard(
                            context: context,
                            mode: 'memory',
                            title: 'Memory of Fierce Struggles',
                            subtitle: 'Attempt History',
                            icon: Icons.history,
                            gradientColors: [
                              const Color.fromARGB(255, 23, 145, 41),
                              const Color.fromARGB(255, 0, 255, 60),
                            ],
                            delay: 200,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizModeCard({
    required BuildContext context,
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
                onTap: () {
                    if (mode == 'memory') {
                      // Open the Memory of Fierce Struggles screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MemoryScreen()),
                      );
                    } else {
                      _startQuiz(context, mode);
                    }
                  },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}