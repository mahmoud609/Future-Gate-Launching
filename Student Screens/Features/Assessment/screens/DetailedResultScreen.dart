import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/QuestionRes.dart';
import '../services/DataService.dart';
import 'AssessmentListScreen.dart';

class DetailedResultScreen extends StatefulWidget {
  final String assessmentResultId;
  final AssessmentResult result;

  const DetailedResultScreen({
    Key? key,
    required this.assessmentResultId,
    required this.result,
  }) : super(key: key);

  @override
  _DetailedResultScreenState createState() => _DetailedResultScreenState();
}

class _DetailedResultScreenState extends State<DetailedResultScreen> {
  bool _showingSummary = true;
  bool _isLoading = true;
  List<QuestionRES> _questions = [];
  List<String?> _userAnswers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssessmentData();
  }

  Future<void> _loadAssessmentData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final assessmentData = await StudentHistoryService.fetchAssessment(widget.result.assessmentId);

      if (assessmentData != null) {
        setState(() {
          _questions = assessmentData.questions;
          _userAnswers = assessmentData.userAnswers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to load assessment data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AssessmentListScreen()),
              (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Assessment Result'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? _buildLoadingView()
            : (_errorMessage != null
            ? _buildErrorView()
            : Column(
          children: [
            // Toggle between summary and detailed view
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showingSummary = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showingSummary
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      child: Text(
                        'Summary',
                        style: TextStyle(
                          color: _showingSummary
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showingSummary = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_showingSummary
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      child: Text(
                        'Review Answers',
                        style: TextStyle(
                          color: !_showingSummary
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content based on selected view
            Expanded(
              child: _showingSummary
                  ? _buildSummaryView()
                  : _buildDetailedAnswersView(),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => AssessmentListScreen()),
                        (route) => false,
                  );
                },
                child: Text('Back to Assessments'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading assessment data...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAssessmentData,
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                widget.result.assessmentName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              _buildScoreCircle(),
              SizedBox(height: 32),
              _buildResultStat(
                'Correct',
                widget.result.totalCorrectAnswers,
                Colors.green,
              ),
              SizedBox(height: 16),
              _buildResultStat(
                'Wrong',
                widget.result.totalWrongAnswers,
                Colors.red,
              ),
              SizedBox(height: 16),
              _buildResultStat(
                'Missed',
                widget.result.totalMissedAnswers,
                Colors.orange,
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getLevelColor(widget.result.level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: _getLevelColor(widget.result.level),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Level: ${widget.result.level}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(widget.result.level),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedAnswersView() {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available for this assessment',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        final userAnswer = index < _userAnswers.length ? _userAnswers[index] : null;
        final isCorrect = userAnswer == question.correctAnswer;
        final isMissed = userAnswer == null;

        Color statusColor = isMissed
            ? Colors.orange
            : (isCorrect ? Colors.green : Colors.red);

        String statusText = isMissed
            ? 'Missed'
            : (isCorrect ? 'Correct' : 'Wrong');

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: statusColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Q${index + 1}: $statusText',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ..._buildOptions(question, userAnswer),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOptions(QuestionRES question, String? userAnswer) {
    final options = <Widget>[];

    for (int i = 0; i < question.options.length; i++) {
      final option = question.options[i];
      final isUserSelection = option == userAnswer;
      final isCorrectAnswer = option == question.correctAnswer;

      Color backgroundColor;
      Color textColor;
      IconData? icon;

      if (isUserSelection && isCorrectAnswer) {
        // User selected the correct answer
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
      } else if (isUserSelection && !isCorrectAnswer) {
        // User selected the wrong answer
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
      } else if (isCorrectAnswer) {
        // This is the correct answer but user didn't select it
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle_outline;
      } else {
        // Regular option
        backgroundColor = Colors.grey.withOpacity(0.05);
        textColor = Colors.black;
        icon = null;
      }

      options.add(
        Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor),
                SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isCorrectAnswer ? FontWeight.bold : null,
                  ),
                ),
              ),
              if (isUserSelection)
                Text(
                  'Your Answer',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (!isUserSelection && isCorrectAnswer)
                Text(
                  'Correct Answer',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return options;
  }

  Widget _buildScoreCircle() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.result.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(widget.result.percentage),
              ),
            ),
            Text(
              'Score: ${widget.result.score}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String title, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value / ${widget.result.totalQuestions}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 75) {
      return Colors.blue;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Expert':
        return Colors.green;
      case 'Advanced':
        return Colors.blue;
      case 'Intermediate':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}