class InternshipModel {
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

  InternshipModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.duration,
    required this.field,
    required this.requirements,
    required this.createdAt,
    this.deadline,
    required this.isActive,
  });

  factory InternshipModel.fromMap(Map<String, dynamic> map) {
    return InternshipModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? '',
      field: map['field'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      deadline: map['deadline'] != null ? DateTime.tryParse(map['deadline']) : null,
      isActive: map['is_active'] ?? true,
    );
  }

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
