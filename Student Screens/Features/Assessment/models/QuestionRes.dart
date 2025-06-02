import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionRES {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int points;

  QuestionRES({
    this.id = '',
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.points = 1,
  });

  factory QuestionRES.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception("Document data is null or not a map");
    }

    return QuestionRES(
      id: doc.id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      points: data['points'] ?? 1,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }
}