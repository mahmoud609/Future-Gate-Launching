// Modern Data Classes
import 'package:flutter/material.dart';

class WorkExperience {
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  String jobType = 'Full-time';
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  void dispose() {
    jobTitleController.dispose();
    companyNameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }
}

class Education {
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final TextEditingController majorController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  void dispose() {
    degreeController.dispose();
    universityController.dispose();
    majorController.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }
}

class Language {
  final TextEditingController languageController = TextEditingController();
  String level = 'Beginner';

  void dispose() {
    languageController.dispose();
  }
}

class Course {
  final TextEditingController courseNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  void dispose() {
    courseNameController.dispose();
    companyNameController.dispose();
    durationController.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }
}