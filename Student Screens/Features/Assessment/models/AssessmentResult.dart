import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentResultF {
  final String id;
  final String userId;
  final String assessmentId;
  final String assessmentName;
  final int totalCorrectAnswers;
  final int totalMissedAnswers;
  final int totalWrongAnswers;
  final String level;
  final double percentage;
  final int score;
  final DateTime timestamp;
  final int totalQuestions;

  AssessmentResultF({
    this.id = '',
    required this.userId,
    required this.assessmentId,
    required this.assessmentName,
    required this.totalCorrectAnswers,
    required this.totalMissedAnswers,
    required this.totalWrongAnswers,
    required this.level,
    required this.percentage,
    required this.score,
    required this.timestamp,
    required this.totalQuestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'assessmentId': assessmentId,
      'assessmentName': assessmentName,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalMissedAnswers': totalMissedAnswers,
      'totalWrongAnswers': totalWrongAnswers,
      'level': level,
      'percentage': percentage,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
      'totalQuestions': totalQuestions,
    };
  }

  factory AssessmentResultF.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AssessmentResultF(
      id: doc.id,
      userId: data['userId'] ?? '',
      assessmentId: data['assessmentId'] ?? '',
      assessmentName: data['assessmentName'] ?? '',
      totalCorrectAnswers: data['totalCorrectAnswers'] ?? 0,
      totalMissedAnswers: data['totalMissedAnswers'] ?? 0,
      totalWrongAnswers: data['totalWrongAnswers'] ?? 0,
      level: data['level'] ?? 'Beginner',
      percentage: (data['percentage'] ?? 0).toDouble(),
      score: data['score'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      totalQuestions: data['totalQuestions'] ?? 0,
    );
  }
}