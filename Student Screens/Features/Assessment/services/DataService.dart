import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/Question.dart'; // لو مش مستخدمه احذفه
import '../models/models.dart';
import '../models/QuestionRes.dart';

// ======================== Models (لو مش موجودة في ملفات منفصلة ضيفهم هنا مؤقتاً) ========================

class AssessmentData {
  final List<QuestionRES> questions;
  final List<String?> userAnswers;

  AssessmentData({
    required this.questions,
    required this.userAnswers,
  });
}


// ========================================================================

class StudentHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final String userId;

  StudentHistoryService({required this.userId});

  // Fetch internship applications from Firebase
  Future<List<InternshipApplication>> getInternshipApplications() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Student_Applicant')
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();

      final applications = snapshot.docs
          .map((doc) => InternshipApplication.fromFirestore(doc))
          .toList();

      // Concurrently fetch internship details
      await Future.wait(applications.map((application) async {
        final querySnapshot = await _firestore
            .collection('interns')
            .where('internshipId', isEqualTo: application.internshipId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          application.title = data['title'];
          application.company = data['company'];
          application.location = data['location'];
          application.type = data['type'];
        }
      }));

      return applications;
    } catch (e) {
      print('Error fetching internship applications: $e');
      return [];
    }
  }

  // Fetch assessment results from Firebase
  Future<List<AssessmentResult>> getAssessmentResults() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Assessment_result')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AssessmentResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching assessment results: $e');
      return [];
    }
  }

  // Fetch ATS results from Supabase
  Future<List<ATSResult>> getATSResults() async {
    try {
      final response = await _supabase
          .from('ats_data')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => ATSResult.fromSupabase(data))
          .toList();
    } catch (e) {
      print('Error fetching ATS results: $e');
      return [];
    }
  }

  // Static method to fetch assessment data for DetailedResultScreen
  static Future<AssessmentData?> fetchAssessment(String assessmentId) async {
    try {
      // 1. Get Assessment Document
      final assessmentDoc = await FirebaseFirestore.instance
          .collection('Assessment')
          .doc(assessmentId)
          .get();

      if (!assessmentDoc.exists) {
        print('Assessment document not found: $assessmentId');
        return null;
      }

      // 2. Get Questions Subcollection
      final questionsSnap = await FirebaseFirestore.instance
          .collection('Assessment')
          .doc(assessmentId)
          .collection('Questions')
          .get();

      // 3. Convert to QuestionRES objects
      final List<QuestionRES> questions = questionsSnap.docs.map((doc) {
        final data = doc.data();
        return QuestionRES(
          id: doc.id,
          question: data['question'] ?? '',
          options: List<String>.from(data['options'] ?? []),
          correctAnswer: data['answer'] ?? '',
        );
      }).toList();

      // 4. Get User's Result Document
      final userAnswersSnap = await FirebaseFirestore.instance
          .collection('Assessment_result')
          .where('assessmentId', isEqualTo: assessmentId)
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .limit(1)
          .get();

      List<String?> userAnswers = List.filled(questions.length, null);

      if (userAnswersSnap.docs.isNotEmpty) {
        final resultData = userAnswersSnap.docs.first.data();
        final answersList = List<Map<String, dynamic>>.from(resultData['answers'] ?? []);

        for (int i = 0; i < questions.length; i++) {
          final q = questions[i];
          final matchedAnswer = answersList.firstWhere(
                (a) => a['questionId'] == q.id,
            orElse: () => {},
          );
          userAnswers[i] = matchedAnswer['userAnswer'];
        }
      }

      return AssessmentData(
        questions: questions,
        userAnswers: userAnswers,
      );
    } catch (e) {
      print('Error fetching assessment data: $e');
      return null;
    }
  }
}
