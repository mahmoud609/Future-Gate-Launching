import 'package:cloud_firestore/cloud_firestore.dart';

class Assessment {
  final String id;
  final String title;
  final int totalQuestions;
  final int timeInMinutes;
  bool attempted;

  Assessment({
    required this.id,
    required this.title,
    required this.totalQuestions,
    required this.timeInMinutes,
    this.attempted = false,
  });

  static Future<Assessment> fromFirestore(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    // Get questions subcollection count
    final questionsSnapshot = await doc.reference.collection('Questions').get();
    final questionCount = questionsSnapshot.docs.length;

    return Assessment(
      id: doc.id,
      title: data['title'] ?? 'Unknown Assessment',
      totalQuestions: questionCount,
      timeInMinutes: questionCount, // 1 min per question
      attempted: data['attempted'] ?? false,
    );
  }
}
