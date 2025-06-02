import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadCVScreen extends StatefulWidget {
  final String internshipId;
  final String internshipTitle;
  const UploadCVScreen({
    Key? key,
    required this.internshipId,
    required this.internshipTitle,
  }) : super(key: key);

  @override
  _UploadCVScreenState createState() => _UploadCVScreenState();
}

class _UploadCVScreenState extends State<UploadCVScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController externalLinkController = TextEditingController();
  final TextEditingController gpaController = TextEditingController();
  String? cvFileName;
  PlatformFile? cvFile;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final double maxFileSizeMB = 5.0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern Color Palette (matching BuildCVScreen)
  final Color _primaryColor = const Color(0xFF6366f1);
  final Color _secondaryColor = const Color(0xFF8b5cf6);
  final Color _accentColor = const Color(0xFF06b6d4);
  final Color _successColor = const Color(0xFF10b981);
  final Color _warningColor = const Color(0xFFf59e0b);
  final Color _errorColor = const Color(0xFFef4444);
  final Color _backgroundColorLight = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _prefillUserData();
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

  Future<void> _prefillUserData() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      emailController.text = user.email!;
    }
  }

  Future<void> _uploadCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileSizeMB = file.size / (1024 * 1024);

        if (fileSizeMB > maxFileSizeMB) {
          _showModernSnackBar('File size exceeds ${maxFileSizeMB}MB limit', isError: true);
          return;
        }

        setState(() {
          cvFileName = file.name;
          cvFile = file;
        });
        _showModernSnackBar('CV selected successfully', isSuccess: true);
      }
    } catch (e) {
      _showModernSnackBar('Error selecting file: ${e.toString()}', isError: true);
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      _showModernSnackBar("Please fill in all required fields", isError: true);
      return;
    }
    if (cvFile == null) {
      _showModernSnackBar("Please upload your CV (PDF only)", isError: true);
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _showModernSnackBar("Please login first", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // 1. Upload to Supabase Storage
      final supabase = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'cv/${user.uid}/${timestamp}_${cvFile!.name}';
      final fileBytes = cvFile!.bytes;

      if (fileBytes == null) throw Exception('File data is null');

      await supabase.storage
          .from('upload-cv')
          .uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'application/pdf',
        ),
      );

      // 2. Get Public URL
      final publicUrl = supabase.storage
          .from('upload-cv')
          .getPublicUrl(filePath);

      // 3. Save to Supabase table
      final supabaseResponse = await supabase
          .from('Uplod-CV')
          .insert({
        'Cv-url': publicUrl,
        'userid': user.uid,
        'National-ID': nationalIdController.text.trim(),
        'Email': emailController.text.trim(),
        'ExternaLink': externalLinkController.text.trim(),
        'Gpa': double.tryParse(gpaController.text.trim()) ?? 0.0,
        'internship_id': widget.internshipId,
      }).select().single();

      final supabaseCvId = supabaseResponse['id'] as int;

      // 4. Save to Firestore
      await FirebaseFirestore.instance.collection('Student_Applicant').add({
        'appliedAt': FieldValue.serverTimestamp(),
        'internshipId': widget.internshipId,
        'internshipTitle': widget.internshipTitle,
        'cvId': publicUrl,
        'email': emailController.text.trim(),
        'status': 'pending',
        'userId': user.uid,
        'uploadMethod': 'upload',
        'supabaseCvId': supabaseCvId,
        'nationalId': nationalIdController.text.trim(),
        'gpa': gpaController.text.trim(),
      });

      HapticFeedback.heavyImpact();
      _showModernSnackBar("Application Submitted Successfully!", isSuccess: true);

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showModernSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      cvFileName = null;
      cvFile = null;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validateRequiredField(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    return null;
  }

  String? _validateGPA(String? value) {
    if (value == null || value.isEmpty) return 'GPA is required';
    final gpa = double.tryParse(value);
    if (gpa == null) return 'Enter a valid number';
    if (gpa < 0 || gpa > 4) return 'GPA must be between 0 and 4';
    return null;
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
                      _buildPersonalInfoSection(),
                      _buildUploadSection(),
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
            "Upload Your Resume",
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
                  Icons.file_upload_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Application Progress",
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
    int totalSections = 4; // email, national ID, GPA, CV

    if (emailController.text.isNotEmpty) filledSections++;
    if (nationalIdController.text.isNotEmpty) filledSections++;
    if (gpaController.text.isNotEmpty) filledSections++;
    if (cvFile != null) filledSections++;

    return filledSections / totalSections;
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
          "National ID",
          nationalIdController,
          prefixIcon: Icons.badge_outlined,
          validator: _validateRequiredField,
          keyboardType: TextInputType.number,
          hintText: "14-digit national ID",
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
          "Portfolio/LinkedIn (Optional)",
          externalLinkController,
          prefixIcon: Icons.link_outlined,
          keyboardType: TextInputType.url,
          hintText: "https://linkedin.com/in/your-profile",
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return _buildModernSectionCard(
      title: "Upload CV",
      icon: Icons.upload_file_outlined,
      iconColor: _accentColor,
      children: [
        GestureDetector(
          onTap: _uploadCV,
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accentColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  cvFile != null ? Icons.check_circle : Icons.cloud_upload,
                  size: 48,
                  color: cvFile != null ? _successColor : _accentColor,
                ),
                const SizedBox(height: 12),
                Text(
                  cvFileName ?? "Select PDF File",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cvFile != null ? _successColor : _accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Max ${maxFileSizeMB}MB • PDF only",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (cvFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton(
              onPressed: _uploadCV,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                side: BorderSide(
                  color: _accentColor.withOpacity(0.3),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Change File"),
            ),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildFloatingSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
              const Icon(Icons.check_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              _isLoading ? "Processing..." : "Submit Application",
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    emailController.dispose();
    nationalIdController.dispose();
    externalLinkController.dispose();
    gpaController.dispose();
    super.dispose();
  }
}
