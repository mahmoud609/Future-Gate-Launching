import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../Apply Process/DataModels/Models.dart';
import 'package:intl/intl.dart';

class BuildCVScreen extends StatefulWidget {
  final String internshipId;
  final String internshipTitle;
  const BuildCVScreen({
    Key? key,
    required this.internshipId,
    required this.internshipTitle,
  }) : super(key: key);

  @override
  State<BuildCVScreen> createState() => _BuildCVScreenState();
}

class _BuildCVScreenState extends State<BuildCVScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern Color Palette
  final Color _primaryColor = const Color(0xFF6366f1);
  final Color _secondaryColor = const Color(0xFF8b5cf6);
  final Color _accentColor = const Color(0xFF06b6d4);
  final Color _successColor = const Color(0xFF10b981);
  final Color _warningColor = const Color(0xFFf59e0b);
  final Color _errorColor = const Color(0xFFef4444);
  final Color _backgroundColorLight = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;

  // Controllers
  final emailController = TextEditingController();
  final gpaController = TextEditingController();
  final nationalIdController = TextEditingController();
  final skillsController = TextEditingController();

  // Dynamic fields
  List<WorkExperience> workExperiences = [];
  List<Language> languages = [];
  List<Course> courses = [];
  List<Education> educations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeForm();
  }

  void _initializeAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  void _initializeForm() {
    workExperiences.add(WorkExperience());
    languages.add(Language());
    courses.add(Course());
    educations.add(Education());
    if (user?.email != null) {
      emailController.text = user!.email!;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    emailController.dispose();
    gpaController.dispose();
    nationalIdController.dispose();
    skillsController.dispose();
    for (var exp in workExperiences) {
      exp.dispose();
    }
    for (var lang in languages) {
      lang.dispose();
    }
    for (var course in courses) {
      course.dispose();
    }
    for (var edu in educations) {
      edu.dispose();
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1e293b),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> saveCV() async {
    if (_isLoading) return;
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      _showModernSnackBar("Please fill in all required fields", isError: true);
      return;
    }
    if (user == null) {
      _showModernSnackBar("Please login first", isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);
      HapticFeedback.mediumImpact();

      final cvData = {
        'userId': user!.uid,
        'email': emailController.text,
        'gpa': gpaController.text,
        'nationalId': nationalIdController.text,
        'skills': skillsController.text.split(',').map((s) => s.trim()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'internshipId': widget.internshipId,
      };

      final cvDocRef = FirebaseFirestore.instance
          .collection('Build_CV')
          .doc(user!.uid);

      await cvDocRef.set(cvData);
      await _saveSubcollections(cvDocRef);
      await _saveApplicantData(cvDocRef.id);

      HapticFeedback.heavyImpact();
      _showModernSnackBar("CV Saved and Application Submitted Successfully", isSuccess: true);

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
    } catch (e) {
      _showModernSnackBar("Error saving CV: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSubcollections(DocumentReference cvDocRef) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var exp in workExperiences) {
      if (exp.jobTitleController.text.isNotEmpty) {
        final docRef = cvDocRef.collection('Work_Experience').doc();
        batch.set(docRef, {
          'jobTitle': exp.jobTitleController.text,
          'companyName': exp.companyNameController.text,
          'jobType': exp.jobType,
          'startDate': exp.startDateController.text,
          'endDate': exp.endDateController.text,
        });
      }
    }

    for (var lang in languages) {
      if (lang.languageController.text.isNotEmpty) {
        final docRef = cvDocRef.collection('Language').doc();
        batch.set(docRef, {
          'language': lang.languageController.text,
          'level': lang.level,
        });
      }
    }

    for (var course in courses) {
      if (course.courseNameController.text.isNotEmpty) {
        final docRef = cvDocRef.collection('Courses').doc();
        batch.set(docRef, {
          'courseName': course.courseNameController.text,
          'companyName': course.companyNameController.text,
          'duration': course.durationController.text,
          'startDate': course.startDateController.text,
          'endDate': course.endDateController.text,
        });
      }
    }

    for (var edu in educations) {
      if (edu.degreeController.text.isNotEmpty) {
        final docRef = cvDocRef.collection('Education').doc();
        batch.set(docRef, {
          'degree': edu.degreeController.text,
          'university': edu.universityController.text,
          'major': edu.majorController.text,
          'startDate': edu.startDateController.text,
          'endDate': edu.endDateController.text,
        });
      }
    }

    await batch.commit();
  }

  Future<void> _saveApplicantData(String cvId) async {
    await FirebaseFirestore.instance.collection('Student_Applicant').add({
      'userId': user!.uid,
      'email': emailController.text,
      'cvId': cvId,
      'appliedFor': widget.internshipTitle,
      'internshipId': widget.internshipId,
      'appliedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'cvType': 'built',
      'uploadMethod': 'built',
    });
  }

  void _showModernSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline :
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: isError ? _errorColor :
        isSuccess ? _successColor : _primaryColor,
        elevation: 8,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 2 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColorLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProgressIndicator(),
                      _buildStepContent(),
                      const SizedBox(height: 100), // Space for floating button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingSubmitButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryColor, _secondaryColor],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Build Your Resume",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            "For ${widget.internshipTitle}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Progress Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e293b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _calculateProgress(),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            "${(_calculateProgress() * 100).round()}% Complete",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    int filledSections = 0;
    int totalSections = 6;

    if (emailController.text.isNotEmpty) filledSections++;
    if (gpaController.text.isNotEmpty) filledSections++;
    if (nationalIdController.text.isNotEmpty) filledSections++;
    if (skillsController.text.isNotEmpty) filledSections++;
    if (workExperiences.any((exp) => exp.jobTitleController.text.isNotEmpty)) filledSections++;
    if (educations.any((edu) => edu.degreeController.text.isNotEmpty)) filledSections++;

    return filledSections / totalSections;
  }

  Widget _buildStepContent() {
    return Column(
      children: [
        _buildPersonalInfoSection(),
        _buildSkillsSection(),
        _buildWorkExperienceSection(),
        _buildEducationSection(),
        _buildLanguagesSection(),
        _buildCoursesSection(),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildModernSectionCard(
      title: "Personal Information",
      icon: Icons.person_outline_rounded,
      iconColor: _primaryColor,
      children: [
        _buildModernTextField(
          "Email Address",
          emailController,
          prefixIcon: Icons.email_outlined,
          readOnly: true,
          keyboardType: TextInputType.emailAddress,
        ),
        _buildModernTextField(
          "GPA (0.0 - 4.0)",
          gpaController,
          prefixIcon: Icons.school_outlined,
          validator: _validateGPA,
          keyboardType: TextInputType.number,
          hintText: "e.g., 3.8",
        ),
        _buildModernTextField(
          "National ID",
          nationalIdController,
          prefixIcon: Icons.badge_outlined,
          validator: _validateNationalId,
          keyboardType: TextInputType.number,
          hintText: "14-digit national ID",
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return _buildModernSectionCard(
      title: "Skills & Expertise",
      icon: Icons.psychology_outlined,
      iconColor: _accentColor,
      children: [
        _buildModernTextField(
          "Skills",
          skillsController,
          prefixIcon: Icons.star_outline_rounded,
          hintText: "Flutter, Firebase, UI/UX Design, Project Management",
          validator: (value) => value?.isEmpty ?? true ? "Skills are required" : null,
          maxLines: 3,
        ),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: _accentColor, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Separate skills with commas. Include both technical and soft skills.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkExperienceSection() {
    return _buildModernSectionCard(
      title: "Work Experience",
      icon: Icons.work_outline_rounded,
      iconColor: _successColor,
      children: [
        for (int i = 0; i < workExperiences.length; i++)
          _buildExperienceFields(workExperiences[i], i),
        _buildModernAddButton(
          text: "Add Work Experience",
          icon: Icons.add_circle_outline_rounded,
          color: _successColor,
          onPressed: () => setState(() => workExperiences.add(WorkExperience())),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return _buildModernSectionCard(
      title: "Education",
      icon: Icons.school_outlined,
      iconColor: _warningColor,
      children: [
        for (int i = 0; i < educations.length; i++)
          _buildEducationFields(educations[i], i),
        _buildModernAddButton(
          text: "Add Education",
          icon: Icons.add_circle_outline_rounded,
          color: _warningColor,
          onPressed: () => setState(() => educations.add(Education())),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return _buildModernSectionCard(
      title: "Languages",
      icon: Icons.translate_outlined,
      iconColor: _secondaryColor,
      children: [
        for (int i = 0; i < languages.length; i++)
          _buildLanguageFields(languages[i], i),
        _buildModernAddButton(
          text: "Add Language",
          icon: Icons.add_circle_outline_rounded,
          color: _secondaryColor,
          onPressed: () => setState(() => languages.add(Language())),
        ),
      ],
    );
  }

  Widget _buildCoursesSection() {
    return _buildModernSectionCard(
      title: "Courses & Certifications",
      icon: Icons.military_tech_outlined,
      iconColor: const Color(0xFFe11d48),
      children: [
        for (int i = 0; i < courses.length; i++)
          _buildCourseFields(courses[i], i),
        _buildModernAddButton(
          text: "Add Course",
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFFe11d48),
          onPressed: () => setState(() => courses.add(Course())),
        ),
      ],
    );
  }

  Widget _buildExperienceFields(WorkExperience exp, int index) {
    return _buildModernFieldGroup(
      index: index,
      title: exp.jobTitleController.text.isEmpty
          ? "Experience ${index + 1}"
          : exp.jobTitleController.text,
      collection: workExperiences,
      color: _successColor,
      onDelete: () => setState(() => workExperiences.removeAt(index)),
      children: [
        _buildModernTextField(
          "Job Title",
          exp.jobTitleController,
          prefixIcon: Icons.work_outline_rounded,
          validator: (value) => value?.isEmpty ?? true ? "Job title is required" : null,
          hintText: "Software Developer",
        ),
        _buildModernTextField(
          "Company Name",
          exp.companyNameController,
          prefixIcon: Icons.business_outlined,
          validator: (value) => value?.isEmpty ?? true ? "Company name is required" : null,
          hintText: "Tech Corp Inc.",
        ),
        _buildModernDropdownField(
          value: exp.jobType,
          items: const ['Full-time', 'Part-time', 'Remote', 'Internship', 'Contract'],
          label: 'Employment Type',
          prefixIcon: Icons.category_outlined,
          onChanged: (value) => setState(() => exp.jobType = value as String? ?? 'Full-time'),
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernDateField(
                "Start Date",
                exp.startDateController,
                prefixIcon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDateField(
                "End Date",
                exp.endDateController,
                prefixIcon: Icons.calendar_today_outlined,
                hintText: "Present",
                isOptional: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEducationFields(Education edu, int index) {
    return _buildModernFieldGroup(
      index: index,
      title: edu.degreeController.text.isEmpty
          ? "Education ${index + 1}"
          : edu.degreeController.text,
      collection: educations,
      color: _warningColor,
      onDelete: () => setState(() => educations.removeAt(index)),
      children: [
        _buildModernTextField(
          "Degree",
          edu.degreeController,
          prefixIcon: Icons.school_outlined,
          validator: (value) => value?.isEmpty ?? true ? "Degree is required" : null,
          hintText: "Bachelor of Science",
        ),
        _buildModernTextField(
          "University/Institution",
          edu.universityController,
          prefixIcon: Icons.account_balance_outlined,
          validator: (value) => value?.isEmpty ?? true ? "University is required" : null,
          hintText: "University of Technology",
        ),
        _buildModernTextField(
          "Major/Field of Study",
          edu.majorController,
          prefixIcon: Icons.subject_outlined,
          validator: (value) => value?.isEmpty ?? true ? "Major is required" : null,
          hintText: "Computer Science",
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernDateField(
                "Start Date",
                edu.startDateController,
                prefixIcon: Icons.calendar_today_outlined,
                customValidator: (startValue, endValue) {
                  return _validateEducationDates(
                      startValue,
                      edu.endDateController.text
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDateField(
                "End Date",
                edu.endDateController,
                prefixIcon: Icons.calendar_today_outlined,
                hintText: "Expected",
                customValidator: (startValue, endValue) {
                  return _validateEducationDates(
                      edu.startDateController.text,
                      endValue
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageFields(Language lang, int index) {
    return _buildModernFieldGroup(
      index: index,
      title: lang.languageController.text.isEmpty
          ? "Language ${index + 1}"
          : lang.languageController.text,
      collection: languages,
      color: _secondaryColor,
      onDelete: () => setState(() => languages.removeAt(index)),
      children: [
        _buildModernTextField(
          "Language",
          lang.languageController,
          prefixIcon: Icons.translate_outlined,
          validator: (value) => value?.isEmpty ?? true ? "Language is required" : null,
          hintText: "English",
        ),
        _buildModernDropdownField(
          value: lang.level,
          items: const ['Beginner', 'Intermediate', 'Advanced', 'Native', 'Fluent'],
          label: 'Proficiency Level',
          prefixIcon: Icons.bar_chart_outlined,
          onChanged: (value) => setState(() => lang.level = value as String? ?? 'Beginner'),
        ),
      ],
    );
  }

  Widget _buildCourseFields(Course course, int index) {
    return _buildModernFieldGroup(
      index: index,
      title: course.courseNameController.text.isEmpty
          ? "Course ${index + 1}"
          : course.courseNameController.text,
      collection: courses,
      color: const Color(0xFFe11d48),
      onDelete: () => setState(() => courses.removeAt(index)),
      children: [
        _buildModernTextField(
          "Course/Certificate Name",
          course.courseNameController,
          prefixIcon: Icons.military_tech_outlined,
          validator: (value) => value?.isEmpty ?? true ? "Course name is required" : null,
          hintText: "Flutter Development Certification",
        ),
        _buildModernTextField(
          "Institution/Provider",
          course.companyNameController,
          prefixIcon: Icons.business_outlined,
          validator: (value) => value?.isEmpty ?? true ? "Institution is required" : null,
          hintText: "Google, Coursera, Udemy",
        ),
        _buildModernTextField(
          "Duration",
          course.durationController,
          prefixIcon: Icons.timer_outlined,
          hintText: "3 months, 40 hours",
          isOptional: true,
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernDateField(
                "Start Date",
                course.startDateController,
                prefixIcon: Icons.calendar_today_outlined,
                isOptional: true,
                customValidator: (startValue, endValue) {
                  return _validateCourseDates(
                      startValue,
                      course.endDateController.text
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernDateField(
                "Completion Date",
                course.endDateController,
                prefixIcon: Icons.calendar_today_outlined,
                isOptional: true,
                customValidator: (startValue, endValue) {
                  return _validateCourseDates(
                      course.startDateController.text,
                      endValue
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTextField(
      String label,
      TextEditingController controller, {
        bool readOnly = false,
        IconData? prefixIcon,
        String? hintText,
        String? Function(String?)? validator,
        TextInputType? keyboardType,
        int maxLines = 1,
        bool isOptional = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1e293b),
        ),
        decoration: InputDecoration(
          labelText: isOptional ? "$label (Optional)" : label,
          hintText: hintText,
          filled: true,
          fillColor: readOnly ? const Color(0xFFF1F5F9) : _cardColor,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: _primaryColor.withOpacity(0.7), size: 22)
              : null,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _errorColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData prefixIcon,
    required void Function(dynamic) onChanged,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField(
        value: value,
        items: items.map((String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1e293b),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: isOptional ? "$label (Optional)" : label,
          filled: true,
          fillColor: _cardColor,
          prefixIcon: Icon(
            prefixIcon,
            color: _primaryColor.withOpacity(0.7),
            size: 22,
          ),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: _primaryColor,
        ),
        borderRadius: BorderRadius.circular(16),
        dropdownColor: _cardColor,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1e293b),
        ),
      ),
    );
  }

  Widget _buildModernDateField(
      String label,
      TextEditingController controller, {
        IconData? prefixIcon,
        String? hintText,
        bool isOptional = false,
        String? Function(String?, String?)? customValidator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) {
            return "Date is required";
          }
          if (customValidator != null) {
            return customValidator(value, null);
          }
          return null;
        },
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1e293b),
        ),
        decoration: InputDecoration(
          labelText: isOptional ? "$label (Optional)" : label,
          hintText: hintText,
          filled: true,
          fillColor: _cardColor,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: _primaryColor.withOpacity(0.7), size: 22)
              : null,
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: _primaryColor),
            onPressed: () => _selectDate(context, controller),
          ),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _errorColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernFieldGroup({
    required int index,
    required String title,
    required List collection,
    required Color color,
    required VoidCallback onDelete,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                ),
                if (collection.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: _errorColor),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAddButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        label: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e293b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(children: children),
        ],
      ),
    );
  }

  Widget _buildFloatingSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: saveCV,
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.check_circle_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              _isLoading ? "Saving..." : "Submit Application",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateGPA(String? value) {
    if (value == null || value.isEmpty) {
      return "GPA is required";
    }
    final gpa = double.tryParse(value);
    if (gpa == null || gpa < 0.0 || gpa > 4.0) {
      return "Please enter a valid GPA between 0.0 and 4.0";
    }
    return null;
  }

  String? _validateNationalId(String? value) {
    if (value == null || value.isEmpty) {
      return "National ID is required";
    }
    if (value.length != 14) {
      return "National ID must be 14 digits";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "National ID must contain only numbers";
    }
    return null;
  }

  String? _validateEducationDates(String? startDate, String? endDate) {
    if (startDate == null || startDate.isEmpty) return null;
    if (endDate == null || endDate.isEmpty) return null;

    try {
      final start = DateFormat('yyyy-MM-dd').parse(startDate);
      final end = DateFormat('yyyy-MM-dd').parse(endDate);

      if (end.isBefore(start)) {
        return "End date cannot be before start date";
      }
    } catch (e) {
      return "Invalid date format";
    }
    return null;
  }

  String? _validateCourseDates(String? startDate, String? endDate) {
    if (startDate == null || startDate.isEmpty) return null;
    if (endDate == null || endDate.isEmpty) return null;

    try {
      final start = DateFormat('yyyy-MM-dd').parse(startDate);
      final end = DateFormat('yyyy-MM-dd').parse(endDate);

      if (end.isBefore(start)) {
        return "Completion date cannot be before start date";
      }
    } catch (e) {
      return "Invalid date format";
    }
    return null;
  }
}