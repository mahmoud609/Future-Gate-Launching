import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

class CourseUploadPage extends StatefulWidget {
  const CourseUploadPage({Key? key}) : super(key: key);

  @override
  _CourseUploadPageState createState() => _CourseUploadPageState();
}

class _CourseUploadPageState extends State<CourseUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyLinkController = TextEditingController();

  XFile? _courseImage;
  XFile? _companyLogo;
  List<XFile> _roadmapImages = [];
  XFile? _videoFile;

  String _companyType = 'online';

  List<Map<String, dynamic>> _companies = [];

  final SupabaseClient _supabase = Supabase.instance.client;

  // Color scheme
  final Color _primaryColor = const Color(0xFF2252A1);
  final Color _accentColor = const Color(0xFF00BFA6);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF2D3748);
  final Color _lightTextColor = const Color(0xFF718096);

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseDescriptionController.dispose();
    _companyNameController.dispose();
    _companyLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _courseImage = XFile(result.files.single.path!);
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _courseImage = pickedFile;
        });
      }
    }
  }

  Future<void> _pickCompanyLogo() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _companyLogo = XFile(result.files.single.path!);
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _companyLogo = pickedFile;
        });
      }
    }
  }

  Future<void> _pickRoadmapImages() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null) {
        setState(() {
          _roadmapImages = result.files.map((file) => XFile(file.path!)).toList();
        });
      }
    } else {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _roadmapImages = pickedFiles;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _videoFile = XFile(result.files.single.path!);
        });
      }
    } else {
      final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _videoFile = pickedFile;
        });
      }
    }
  }

  Future<String> _uploadFile(XFile file, String bucketName) async {
    final fileExtension = path.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final fileBytes = await file.readAsBytes();

    await _supabase.storage.from(bucketName).uploadBinary(fileName, fileBytes);

    return _supabase.storage.from(bucketName).getPublicUrl(fileName);
  }

  void _addCompany() {
    if (_companyNameController.text.isEmpty) {
      _showSnackBar('Company name is required', isError: true);
      return;
    }

    setState(() {
      _companies.add({
        'name': _companyNameController.text,
        'link': _companyLinkController.text,
        'logo': _companyLogo,
        'type': _companyType,
      });

      // Clear fields
      _companyNameController.clear();
      _companyLinkController.clear();
      _companyLogo = null;
      _companyType = 'online';
    });

    _showSnackBar('Company added successfully');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade700 : _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_courseImage == null || _videoFile == null) {
      _showSnackBar(
        'Please upload both a course image and a video before submitting.',
        isError: true,
      );
      return;
    }

    try {
      // Show loading indicator
      _showLoadingDialog();

      // Upload files to Supabase
      final imageUrl = await _uploadFile(_courseImage!, 'course-images');
      final videoUrl = await _uploadFile(_videoFile!, 'course-videos');

      List<String> roadmapUrls = [];
      for (var image in _roadmapImages) {
        final url = await _uploadFile(image, 'roadmap-images');
        roadmapUrls.add(url);
      }

      // Upload course data
      final courseResponse = await _supabase.from('courses').insert({
        'name': _courseNameController.text,
        'description': _courseDescriptionController.text,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'roadmap_images': roadmapUrls,
      }).select();

      if (courseResponse.isEmpty) throw Exception('Failed to create course');

      final courseId = courseResponse.first['id'];

      // Upload companies data
      for (var company in _companies) {
        String? logoUrl;
        if (company['logo'] != null) {
          logoUrl = await _uploadFile(company['logo'] as XFile, 'company-logos');
        }

        await _supabase.from('companies').insert({
          'course_id': courseId,
          'name': company['name'],
          'link': company['link'],
          'logo_url': logoUrl,
          'type': company['type'],
        });
      }

      // Hide loading indicator
      Navigator.of(context).pop();

      _showSnackBar('Course uploaded successfully!');

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _courseImage = null;
        _videoFile = null;
        _roadmapImages = [];
        _companies = [];
      });
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();

      _showSnackBar('Error: ${e.toString()}', isError: true);
      debugPrint('Error: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Uploading your course...',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile? file) {
    if (file == null) return const SizedBox.shrink();

    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildVideoPreview(XFile? file) {
    if (file == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videocam, size: 36, color: _primaryColor),
        const SizedBox(height: 8),
        Text(
          path.basename(file.path),
          style: TextStyle(
            fontSize: 12,
            color: _lightTextColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: _lightTextColor.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: _textColor),
        ),
      ],
    );
  }

  Widget _buildFileSelector({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Widget? preview,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                'Select File',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 16),
            if (preview != null)
              Expanded(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: preview,
                ),
              ),
          ],
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              helperText,
              style: TextStyle(
                fontSize: 12,
                color: _lightTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompanyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Type',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _companyType = 'online';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _companyType == 'online'
                          ? _primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.language,
                          color: _companyType == 'online'
                              ? _primaryColor
                              : _lightTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: _companyType == 'online'
                                ? _primaryColor
                                : _lightTextColor,
                            fontWeight: _companyType == 'online'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _companyType = 'offline';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _companyType == 'offline'
                          ? _primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _companyType == 'offline'
                              ? _primaryColor
                              : _lightTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Offline',
                          style: TextStyle(
                            color: _companyType == 'offline'
                                ? _primaryColor
                                : _lightTextColor,
                            fontWeight: _companyType == 'offline'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: company['logo'] != null
                  ? _buildImagePreview(company['logo'])
                  : Icon(Icons.business, color: _primaryColor),
            ),
            title: Text(
              company['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            subtitle: Text(
              company['link'] ?? '',
              style: TextStyle(
                color: _lightTextColor,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _companies.removeAt(index);
                });
                _showSnackBar('Company removed');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: company['type'] == 'online'
                        ? _primaryColor.withOpacity(0.1)
                        : _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        company['type'] == 'online'
                            ? Icons.language
                            : Icons.location_on,
                        size: 14,
                        color: company['type'] == 'online'
                            ? _primaryColor
                            : _accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        company['type'] == 'online' ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: company['type'] == 'online'
                              ? _primaryColor
                              : _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Upload New Course',
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _backgroundColor,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: _textColor, size: 20),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Course Details'),
                    const SizedBox(height: 16),

                    // Course Image
                    _buildFileSelector(
                      label: 'Course Image',
                      icon: Icons.photo_library,
                      onPressed: _pickImage,
                      preview: _courseImage != null
                          ? _buildImagePreview(_courseImage)
                          : null,
                      helperText: 'Recommended size: 1280x720 pixels',
                    ),
                    const SizedBox(height: 24),

                    // Course name
                    _buildInputField(
                      controller: _courseNameController,
                      label: 'Course Name',
                      hintText: 'Enter course name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Course name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Course description
                    _buildInputField(
                      controller: _courseDescriptionController,
                      label: 'Course Description',
                      hintText: 'Describe what students will learn in this course',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Course description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Course video
                    _buildFileSelector(
                      label: 'Course Introduction Video',
                      icon: Icons.videocam,
                      onPressed: _pickVideo,
                      preview: _videoFile != null
                          ? _buildVideoPreview(_videoFile)
                          : null,
                      helperText: 'Upload a video introduction to your course',
                    ),
                    const SizedBox(height: 24),

                    // Roadmap images
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Roadmap Images',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _pickRoadmapImages,
                          icon: const Icon(Icons.add_photo_alternate, size: 20),
                          label: Text(
                            'Select Roadmap Images',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_roadmapImages.isNotEmpty)
                          Container(
                            height: 120,
                            margin: const EdgeInsets.only(top: 12),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _roadmapImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildImagePreview(_roadmapImages[index]),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload images that show the learning path of your course',
                          style: TextStyle(
                            fontSize: 12,
                            color: _lightTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Companies section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Offering Companies'),
                    const SizedBox(height: 16),

                    // Company name
                    _buildInputField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      hintText: 'Enter company name',
                    ),
                    const SizedBox(height: 24),

                    // Company website
                    _buildInputField(
                      controller: _companyLinkController,
                      label: 'Company Website',
                      hintText: 'https://example.com',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),

                    // Company Type
                    _buildCompanyTypeSelector(),
                    const SizedBox(height: 24),

                    // Company logo
                    _buildFileSelector(
                      label: 'Company Logo',
                      icon: Icons.image,
                      onPressed: _pickCompanyLogo,
                      preview: _companyLogo != null
                          ? _buildImagePreview(_companyLogo)
                          : null,
                      helperText: 'Recommended size: 200x200 pixels',
                    ),
                    const SizedBox(height: 24),

                    // Add company button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _addCompany,
                        icon: const Icon(Icons.add_business, size: 20),
                        label: const Text(
                          'Add Company',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    // Added companies list
                    if (_companies.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Added Companies',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _companies.length,
                            itemBuilder: (context, index) {
                              return _buildCompanyCard(_companies[index], index);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: _submitCourse,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Upload Course',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}