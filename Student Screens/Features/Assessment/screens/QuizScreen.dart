import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/Assessment.dart';
import '../models/AssessmentResult.dart';
import '../models/Question.dart';
import 'package:project/Student Screens/Features/Assessment/services/AuthService.dart';
import '../services/FirebaseService.dart';
import '../widgets/CountdownTimer.dart';
import '../widgets/QuestionWidget.dart';
import 'ResultScreen.dart';

class QuizScreen extends StatefulWidget {
  final Assessment assessment;

  const QuizScreen({
    Key? key,
    required this.assessment,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late FirebaseService _firebaseService;
  late AuthService _authService;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Question> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isSubmitting = false;
  int _secondsRemaining = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final questions = await _firebaseService.getQuestionsForAssessment(widget.assessment.id);

      for (var question in questions) {
        question.options.shuffle();
      }

      if (mounted) {
        setState(() {
          _questions = questions;
          _secondsRemaining = widget.assessment.timeInMinutes * 60;
          _isLoading = false;
        });
        _fadeController.forward();
      }

      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load questions: $e');
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer.cancel();
        _submitAssessment();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  List<Map<String, dynamic>> _createAnswersArray() {
    List<Map<String, dynamic>> answers = [];

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final isCorrect = question.selectedOption == question.answer;
      final isAnswered = question.selectedOption != null;

      answers.add({
        'questionIndex': i + 1,
        'questionId': question.id ?? 'question_${i + 1}',
        'questionText': question.questionText,
        'correctAnswer': question.answer,
        'userAnswer': question.selectedOption,
        'allOptions': question.options,
        'isCorrect': isCorrect,
        'isAnswered': isAnswered,
        'status': isAnswered
            ? (isCorrect ? 'correct' : 'wrong')
            : 'missed',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return answers;
  }

  Future<void> _submitAssessment() async {
    if (_isSubmitting) return;

    if (mounted) {
      setState(() {
        _isSubmitting = true;
      });
    }

    try {
      int totalCorrect = 0;
      int totalWrong = 0;
      int totalMissed = 0;

      final answersArray = _createAnswersArray();

      for (var answer in answersArray) {
        switch (answer['status']) {
          case 'correct':
            totalCorrect++;
            break;
          case 'wrong':
            totalWrong++;
            break;
          case 'missed':
            totalMissed++;
            break;
        }
      }

      final percentage = (totalCorrect / _questions.length) * 100;
      final score = totalCorrect * 10;

      String level;
      if (percentage >= 90) {
        level = 'Expert';
      } else if (percentage >= 75) {
        level = 'Advanced';
      } else if (percentage >= 50) {
        level = 'Intermediate';
      } else {
        level = 'Beginner';
      }

      final result = AssessmentResultF(
        userId: _authService.userId,
        assessmentId: widget.assessment.id,
        assessmentName: widget.assessment.title,
        totalCorrectAnswers: totalCorrect,
        totalMissedAnswers: totalMissed,
        totalWrongAnswers: totalWrong,
        level: level,
        percentage: percentage,
        score: score,
        timestamp: DateTime.now(),
        totalQuestions: _questions.length,
      );

      await _firebaseService.saveAssessmentResultWithAnswers(result, answersArray);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResultScreen(result: result),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 600),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorSnackBar('Failed to submit assessment: $e');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return false;

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.orange.shade700),
            ),
            SizedBox(width: 12),
            Text('Leave Assessment?'),
          ],
        ),
        content: Text(
          'Your progress will be lost and this will count as an incomplete assessment. Are you sure you want to leave?',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text('Leave'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _navigateToQuestion(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildModernProgressBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((_currentIndex + 1) / _questions.length * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigation() {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          bool isAnswered = _questions[index].selectedOption != null;
          bool isCurrent = index == _currentIndex;

          return GestureDetector(
            onTap: () => _navigateToQuestion(index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: 8),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCurrent
                    ? Colors.blue.shade600
                    : isAnswered
                    ? Colors.green.shade500
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isCurrent
                    ? [
                  BoxShadow(
                    color: Colors.blue.shade300,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
                    : [],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent || isAnswered ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  );
                },
                icon: Icon(Icons.arrow_back_ios, size: 18),
                label: Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          if (_currentIndex > 0 && _currentIndex < _questions.length - 1)
            SizedBox(width: 16),

          if (_currentIndex < _questions.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  );
                },
                icon: Icon(Icons.arrow_forward_ios, size: 18),
                label: Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitAssessment,
                icon: _isSubmitting
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(Icons.check_circle, size: 18),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
          title: Text(
            widget.assessment.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16),
              child: CountdownTimer(secondsRemaining: _secondsRemaining),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        body: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              SizedBox(height: 24),
              Text(
                'Loading questions...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildModernProgressBar(),
              SizedBox(height: 16),
              _buildQuestionNavigation(),
              SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      child: QuestionWidget(
                        question: _questions[index],
                        onOptionSelected: (option) {
                          setState(() {
                            _questions[index].selectedOption = option;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }
}