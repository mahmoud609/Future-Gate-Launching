import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String question;
  final List<String> options;
  final String answer;
  String? selectedOption;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    this.selectedOption,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      question: data['question'] ?? 'Unknown Question',
      options: List<String>.from(data['options'] ?? []),
      answer: data['answer'] ?? '',
    );
  }

  get questionText => null;
}
