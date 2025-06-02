import 'package:flutter/material.dart';
import '../models/AssessmentResult.dart';
import 'AssessmentListScreen.dart';


class ResultScreen extends StatelessWidget {
  final AssessmentResultF result;

  const ResultScreen({
    Key? key,
    required this.result,
  }) : super(key: key);

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
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        result.assessmentName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      _buildScoreCircle(context),
                      SizedBox(height: 32),
                      _buildResultStat(
                        context,
                        'Correct',
                        result.totalCorrectAnswers,
                        Colors.green,
                      ),
                      SizedBox(height: 16),
                      _buildResultStat(
                        context,
                        'Wrong',
                        result.totalWrongAnswers,
                        Colors.red,
                      ),
                      SizedBox(height: 16),
                      _buildResultStat(
                        context,
                        'Missed',
                        result.totalMissedAnswers,
                        Colors.orange,
                      ),
                      SizedBox(height: 32),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getLevelColor(result.level).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: _getLevelColor(result.level),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Level: ${result.level}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getLevelColor(result.level),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCircle(BuildContext context) {
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
              '${result.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(result.percentage),
              ),
            ),
            Text(
              'Score: ${result.score}',
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

  Widget _buildResultStat(BuildContext context, String title, int value, Color color) {
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
            '$value / ${result.totalQuestions}',
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
