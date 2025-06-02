import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

// Model classes from the original code
class InternshipApplication {
  final String internshipId;
  final String internshipTitle;
  final String status;
  final DateTime appliedAt;
  final String userId;
  String? title;
  String? company;
  String? location;
  String? type;

  InternshipApplication({
    required this.internshipId,
    required this.internshipTitle,
    required this.status,
    required this.appliedAt,
    required this.userId,
    this.title,
    this.company,
    this.location,
    this.type,
  });

  factory InternshipApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InternshipApplication(
      internshipId: data['internshipId'] ?? '',
      internshipTitle: data['internshipTitle'] ?? '',
      status: data['status'] ?? 'Pending',
      appliedAt: data['appliedAt']?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }
}

class AssessmentResult {
  final String id; // Added field for the document ID
  final String assessmentId; // Added field for the assessment reference
  final String assessmentName;
  final String level;
  final int score;
  final double percentage;
  final int totalCorrectAnswers;
  final int totalWrongAnswers;
  final int totalMissedAnswers; // Added for DetailedResultScreen
  final int totalQuestions; // Added for DetailedResultScreen
  final DateTime timestamp;
  final String userId;

  AssessmentResult({
    required this.id,
    required this.assessmentId,
    required this.assessmentName,
    required this.level,
    required this.score,
    required this.percentage,
    required this.totalCorrectAnswers,
    required this.totalWrongAnswers,
    required this.totalMissedAnswers,
    required this.totalQuestions,
    required this.timestamp,
    required this.userId,
  });

  factory AssessmentResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final totalCorrect = data['totalCorrectAnswers'] ?? 0;
    final totalWrong = data['totalWrongAnswers'] ?? 0;
    final totalQuestions = data['totalQuestions'] ?? (totalCorrect + totalWrong);

    return AssessmentResult(
      id: doc.id,
      assessmentId: data['assessmentId'] ?? '',
      assessmentName: data['assessmentName'] ?? '',
      level: data['level'] ?? '',
      score: data['score'] ?? 0,
      percentage: (data['percentage'] ?? 0).toDouble(),
      totalCorrectAnswers: totalCorrect,
      totalWrongAnswers: totalWrong,
      totalMissedAnswers: totalQuestions - (totalCorrect + totalWrong),
      totalQuestions: totalQuestions,
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }
}

class ATSResult {
  final String fileName;
  final double percentageCV;
  final String jobDescription;
  final String analysisResult;
  final DateTime createdAt;
  final String userId;

  ATSResult({
    required this.fileName,
    required this.percentageCV,
    required this.jobDescription,
    required this.analysisResult,
    required this.createdAt,
    required this.userId,
  });

  factory ATSResult.fromSupabase(Map<String, dynamic> data) {
    return ATSResult(
      fileName: data['file_name'] ?? '',
      percentageCV: (data['percentage_cv'] ?? 0).toDouble(),
      jobDescription: data['job_description'] ?? '',
      analysisResult: data['analysis_result'] ?? '',
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      userId: data['user_id'] ?? '',
    );
  }
}