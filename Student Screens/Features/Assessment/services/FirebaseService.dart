import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/Assessment.dart';
import '../models/AssessmentResult.dart';
import '../models/Question.dart';
import '../models/StudentApplicationModel.dart';


class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const String _assessmentCollection = 'Assessment';
  static const String _assessmentResultCollection = 'Assessment_result';
  static const String _questionsSubcollection = 'Questions';

  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Stream<List<Assessment>> getAssessments() {
    return _firestore.collection(_assessmentCollection).snapshots().asyncMap(
          (snapshot) async {
        return await Future.wait(
          snapshot.docs.map((doc) => Assessment.fromFirestore(doc)),
        );
      },
    );
  }

  Future<bool> hasAttemptedAssessment(String assessmentId) async {
    try {
      final result = await _firestore
          .collection(_assessmentResultCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('assessmentId', isEqualTo: assessmentId)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check assessment attempt: $e');
    }
  }

  Future<List<Question>> getQuestionsForAssessment(String assessmentId) async {
    try {
      final snapshot = await _firestore
          .collection(_assessmentCollection)
          .doc(assessmentId)
          .collection(_questionsSubcollection)
          .get();

      return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  // Original save method - kept for backward compatibility
  Future<void> saveAssessmentResult(AssessmentResultF result) async {
    try {
      await _firestore.collection(_assessmentResultCollection).add({
        ...result.toMap(),
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save result: $e');
    }
  }

  // New enhanced save method with detailed answers
  Future<void> saveAssessmentResultWithAnswers(
      AssessmentResultF result,
      List<Map<String, dynamic>> answers,
      ) async {
    try {
      // Prepare answers with only minimal data
      final simplifiedAnswers = answers.map((a) => {
        'questionId': a['questionId'],
        'userAnswer': a['userAnswer'],
        'status': a['status'],
      }).toList();

      final resultData = {
        ...result.toMap(),
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'assessmentId': result.assessmentId,
        'answers': simplifiedAnswers,
        'answersCount': {
          'total': simplifiedAnswers.length,
          'correct': simplifiedAnswers.where((a) => a['status'] == 'correct').length,
          'wrong': simplifiedAnswers.where((a) => a['status'] == 'wrong').length,
          'missed': simplifiedAnswers.where((a) => a['status'] == 'missed').length,
        },
      };

      await _firestore.collection(_assessmentResultCollection).add(resultData);
    } catch (e) {
      throw Exception('Failed to save assessment result: $e');
    }
  }

  Stream<List<AssessmentResultF>> getUserResults() {
    try {
      return _firestore
          .collection(_assessmentResultCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
        print('Error in getUserResults stream: $error');
        return Stream.value(<AssessmentResultF>[]);
      })
          .map((snapshot) => snapshot.docs
          .map((doc) => AssessmentResultF.fromFirestore(doc))
          .toList());
    } catch (e) {
      print('Error creating getUserResults stream: $e');
      return Stream.value(<AssessmentResultF>[]);
    }
  }

  // Get detailed answers for a specific assessment result
  Future<List<Map<String, dynamic>>> getResultWithQuestions(String resultDocId) async {
    try {
      final resultDoc = await _firestore.collection(_assessmentResultCollection).doc(resultDocId).get();

      if (!resultDoc.exists) return [];

      final resultData = resultDoc.data()!;
      final assessmentId = resultData['assessmentId'];
      final answers = List<Map<String, dynamic>>.from(resultData['answers']);

      List<Map<String, dynamic>> fullAnswers = [];

      for (var answer in answers) {
        final questionId = answer['questionId'];

        final questionDoc = await _firestore
            .collection('Assessment')
            .doc(assessmentId)
            .collection('Questions')
            .doc(questionId)
            .get();

        if (questionDoc.exists) {
          final questionData = questionDoc.data()!;
          fullAnswers.add({
            'questionText': questionData['questionText'],
            'options': questionData['options'],
            'correctAnswer': questionData['correctAnswer'],
            'userAnswer': answer['userAnswer'],
            'status': answer['status'],
          });
        }
      }

      return fullAnswers;
    } catch (e) {
      throw Exception('Error fetching result with questions: $e');
    }
  }


  // Get assessment result with detailed answers by document ID
  Future<Map<String, dynamic>?> getAssessmentResultWithAnswers(String resultDocId) async {
    try {
      final doc = await _firestore
          .collection(_assessmentResultCollection)
          .doc(resultDocId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return {
        'result': data,
        'answers': data.containsKey('answers') ? List<Map<String, dynamic>>.from(data['answers']) : [],
        'hasDetailedAnswers': data.containsKey('answers') && data['answers'] is List,
      };
    } catch (e) {
      throw Exception('Failed to load assessment result with answers: $e');
    }
  }

  // Get all assessment results with their detailed answers for a user
  Future<List<Map<String, dynamic>>> getUserResultsWithAnswers() async {
    try {
      final snapshot = await _firestore
          .collection(_assessmentResultCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'docId': doc.id,
          'result': AssessmentResultF.fromFirestore(doc),
          'answers': data.containsKey('answers') ? List<Map<String, dynamic>>.from(data['answers']) : [],
          'hasDetailedAnswers': data.containsKey('answers') && data['answers'] is List,
          'answersCount': data.containsKey('answersCount') ? data['answersCount'] : null,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load user results with answers: $e');
    }
  }

  // Search answers by question text or status
  Future<List<Map<String, dynamic>>> searchUserAnswers({
    String? assessmentId,
    String? questionText,
    String? status, // 'correct', 'wrong', 'missed'
  }) async {
    try {
      Query query = _firestore
          .collection(_assessmentResultCollection)
          .where('userId', isEqualTo: currentUserId);

      if (assessmentId != null) {
        query = query.where('assessmentId', isEqualTo: assessmentId);
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> allAnswers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('answers') && data['answers'] is List) {
          final answers = List<Map<String, dynamic>>.from(data['answers']);

          // Filter answers based on criteria
          final filteredAnswers = answers.where((answer) {
            bool matches = true;

            if (questionText != null && questionText.isNotEmpty) {
              matches = matches && answer['questionText']
                  .toString()
                  .toLowerCase()
                  .contains(questionText.toLowerCase());
            }

            if (status != null) {
              matches = matches && answer['status'] == status;
            }

            return matches;
          }).toList();

          // Add assessment info to each answer
          for (var answer in filteredAnswers) {
            answer['assessmentName'] = data['assessmentName'];
            answer['assessmentId'] = data['assessmentId'];
            answer['resultDocId'] = doc.id;
            answer['completedAt'] = data['timestamp'];
          }

          allAnswers.addAll(filteredAnswers);
        }
      }

      return allAnswers;
    } catch (e) {
      throw Exception('Failed to search user answers: $e');
    }
  }

  // Original method - kept for backward compatibility but enhanced
  Future<Map<String, dynamic>> getUserAnswersForAssessment(String assessmentId, String currentUserId) async {
    try {
      final resultSnapshot = await _firestore
          .collection(_assessmentResultCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('assessmentId', isEqualTo: assessmentId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (resultSnapshot.docs.isEmpty) {
        return {};
      }

      final data = resultSnapshot.docs.first.data();

      // Check for new detailed answers format first
      if (data.containsKey('answers') && data['answers'] is List) {
        final answers = List<Map<String, dynamic>>.from(data['answers']);
        // Convert to old format for backward compatibility
        Map<String, dynamic> oldFormat = {};
        for (int i = 0; i < answers.length; i++) {
          oldFormat['question_${i + 1}'] = answers[i]['userAnswer'];
        }
        return oldFormat;
      }
      // Fallback to old format
      else if (data.containsKey('answers') && data['answers'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['answers']);
      } else {
        return {};
      }
    } catch (e) {
      throw Exception('Failed to load user answers: $e');
    }
  }

  Future<List<StudentApplicationModel>> getAllStudentApplicants() async {
    try {
      final snapshot = await _firestore
          .collection('Student_Applicant')
          .where('userId', isEqualTo: currentUserId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StudentApplicationModel.fromSupabaseMap({
          'id': doc.id,
          'internshipId': data['internshipId'] ?? '',
          'userId': data['userId'] ?? '',
          'email': data['email'] ?? '',
          'gpa': data['gpa']?.toString() ?? '0',
          'status': data['status'] ?? 'pending',
          'appliedAt': (data['appliedAt'] as Timestamp).toDate().toIso8601String(),
          'cvId': data['cvId'] ?? data['supabaseCvId'] ?? '',
          'uploadMethod': data['uploadMethod'] ?? '',
          'internshipTitle': data['internshipTitle'] ?? '',
          'nationalId': data['nationalId'] ?? '',
          'cvType': data['cvType'] ?? data['uploadMethod'] ?? '',
        });
      }).toList();
    } catch (e) {
      print('Error loading student applicants: $e');
      return [];
    }
  }

  Future<void> applyForInternship({
    required String internshipId,
    required String email,
    required String gpa,
    required String cvId,
    required String uploadMethod,
    required String internshipTitle,
    required String nationalId,
    String? cvType,
  }) async {
    try {
      await _firestore.collection('Student_Applicant').add({
        'internshipId': internshipId,
        'userId': currentUserId,
        'email': email,
        'gpa': gpa,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'cvId': cvId,
        'uploadMethod': uploadMethod,
        'internshipTitle': internshipTitle,
        'nationalId': nationalId,
        'cvType': cvType ?? uploadMethod,
      });
    } catch (e) {
      throw Exception('Failed to apply for internship: $e');
    }
  }

  Future<List<Internship>> getAllInternships() async {
    try {
      final snapshot = await _firestore.collection('interns').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Internship.fromMap({
          'id': doc.id,
          'title': data['title'] ?? data['internship'] ?? '',
          'company': data['company'] ?? '',
          'description': data['whatYouWillBeDoing'] ?? '',
          'duration': data['duration'] ?? '',
          'field': data['field'] ?? '',
          'requirements': List<String>.from(data['preferredQualifications'] ??
              data['requirements'] ??
              data['qualifications'] ?? []),
          'created_at': (data['timestamp'] as Timestamp?)?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
          'deadline': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
          'is_active': data['isActive'] ?? true,
          'location': data['location'] ?? '',
          'type': data['type'] ?? '',
          'companyImageUrl': data['companyImageUrl'] ?? '',
        });
      }).toList();
    } catch (e) {
      print('Error loading internships: $e');
      throw Exception('Failed to load internships');
    }
  }

  Future<Internship?> getInternshipById(String internshipId) async {
    try {
      final doc = await _firestore
          .collection('interns')
          .where('internshipId', isEqualTo: internshipId)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) {
        return null;
      }

      final data = doc.docs.first.data();
      return Internship.fromMap({
        'id': doc.docs.first.id,
        'title': data['title'] ?? data['internship'] ?? '',
        'company': data['company'] ?? '',
        'description': data['whatYouWillBeDoing'] ?? '',
        'duration': data['duration'] ?? '',
        'field': data['field'] ?? '',
        'requirements': List<String>.from(data['preferredQualifications'] ??
            data['requirements'] ??
            data['qualifications'] ?? []),
        'created_at': (data['timestamp'] as Timestamp?)?.toDate().toIso8601String() ??
            DateTime.now().toIso8601String(),
        'deadline': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
        'is_active': data['isActive'] ?? true,
        'location': data['location'] ?? '',
        'type': data['type'] ?? '',
        'companyImageUrl': data['companyImageUrl'] ?? '',
      });
    } catch (e) {
      print('Error getting internship: $e');
      return null;
    }
  }

  Future<Assessment?> getAssessment(String assessmentId) async {
    try {
      final doc = await _firestore
          .collection(_assessmentCollection)
          .doc(assessmentId)
          .get();
      return doc.exists ? Assessment.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get assessment: $e');
    }
  }

  Widget buildErrorCard(BuildContext context, String message) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}