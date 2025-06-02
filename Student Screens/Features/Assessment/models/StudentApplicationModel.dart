// Student Application Model
class StudentApplicationModel {
  final String id;
  final String userId;
  final String internshipId;
  final String internshipTitle;
  final String company;
  final String field;
  final String status;
  final DateTime appliedAt;
  final String? cvId;
  final String? cvType;
  final String? cvUrl;
  final double? gpa;

  StudentApplicationModel({
    required this.id,
    required this.userId,
    required this.internshipId,
    required this.internshipTitle,
    required this.company,
    required this.field,
    required this.status,
    required this.appliedAt,
    this.cvId,
    this.cvType,
    this.cvUrl,
    this.gpa,
  });

  // Factory constructor to create a StudentApplicationModel from a Supabase map
  factory StudentApplicationModel.fromSupabaseMap(Map<String, dynamic> map) {
    return StudentApplicationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      internshipId: map['internshipId'] ?? '',
      internshipTitle: map['internshipId']?['title'] ?? 'Unknown Internship',
      company: map['internshipId']?['company'] ?? 'Unknown Company',
      field: map['internshipId']?['field'] ?? 'Unknown Field',
      status: map['status'] ?? 'pending',
      appliedAt: DateTime.parse(map['appliedAt'] ?? DateTime.now().toIso8601String()),
      cvId: map['cvId'],
      cvType: map['cvType'],
      cvUrl: map['uploadMethod'] == 'upload' ? map['supabaseCvId'] : null,
      gpa: double.tryParse(map['gpa']?.toString() ?? '0'),
    );
  }

  // To Map method for potential future use
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'internshipId': internshipId,
      'status': status,
      'appliedAt': appliedAt.toIso8601String(),
      'cvId': cvId,
      'cvType': cvType,
      'cvUrl': cvUrl,
      'gpa': gpa,
    };
  }
}

// ATS Analysis Model
class ATSAnalysisModel {
  final String id;
  final int percentageCv;
  final String fileName;
  final String jobDescription;
  final String analysisResult;
  final DateTime createdAt;
  final String? userId;
  final String? pdfUrl;

  ATSAnalysisModel({
    required this.id,
    required this.percentageCv,
    required this.fileName,
    required this.jobDescription,
    required this.analysisResult,
    required this.createdAt,
    this.userId,
    this.pdfUrl,
  });

  // Factory constructor to create an ATSAnalysisModel from a Supabase map
  factory ATSAnalysisModel.fromSupabaseMap(Map<String, dynamic> map) {
    return ATSAnalysisModel(
      id: map['id'] ?? '',
      percentageCv: map['percentage_cv'] ?? 0,
      fileName: map['file_name'] ?? 'Unnamed CV',
      jobDescription: map['job_description'] ?? 'No job description',
      analysisResult: map['analysis_result'] ?? 'No analysis',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      userId: map['user_id'],
      pdfUrl: map['pdf_url'],
    );
  }

  // To Map method for potential future use
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'percentage_cv': percentageCv,
      'file_name': fileName,
      'job_description': jobDescription,
      'analysis_result': analysisResult,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'pdf_url': pdfUrl,
    };
  }
}

// Extend InternshipModel to include more details
class Internship {
  final String id;
  final String title;
  final String company;
  final String description;
  final String duration;
  final String field;
  final List<String> requirements;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isActive;

  Internship({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.duration,
    required this.field,
    required this.requirements,
    required this.createdAt,
    this.deadline,
    this.isActive = true,
  });

  // Factory method to create an Internship from a map
  factory Internship.fromMap(Map<String, dynamic> map) {
    return Internship(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? '',
      field: map['field'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : null,
      isActive: map['is_active'] ?? true,
    );
  }

  // To Map method for potential future use
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'description': description,
      'duration': duration,
      'field': field,
      'requirements': requirements,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'is_active': isActive,
    };
  }
}