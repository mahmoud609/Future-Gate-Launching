import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

import 'loading_provider.dart';

class AddCompaniesPage extends StatefulWidget {
  final int courseId;

  const AddCompaniesPage({Key? key, required this.courseId}) : super(key: key);

  @override
  _AddCompaniesPageState createState() => _AddCompaniesPageState();
}

class _AddCompaniesPageState extends State<AddCompaniesPage> {
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  final _companyLinkController = TextEditingController();
  final _companyContactController = TextEditingController();

  XFile? _companyLogo;
  List<Map<String, dynamic>> _companies = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  final LoadingProvider _loadingProvider = LoadingProvider();

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _companyLinkController.dispose();
    _companyContactController.dispose();
    super.dispose();
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

  Future<String> _uploadFile(XFile file, String bucketName) async {
    final fileExtension = path.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final fileBytes = await file.readAsBytes();

    await _supabase.storage.from(bucketName).uploadBinary(fileName, fileBytes);

    return _supabase.storage.from(bucketName).getPublicUrl(fileName);
  }

  void _addCompany() {
    if (_companyNameController.text.isEmpty) return;

    setState(() {
      _companies.add({
        'name': _companyNameController.text,
        'description': _companyDescriptionController.text,
        'link': _companyLinkController.text,
        'logo': _companyLogo,
      });

      // Clear fields
      _companyNameController.clear();
      _companyDescriptionController.clear();
      _companyLinkController.clear();
      _companyLogo = null;
    });
  }

  Future<void> _submitCompanies() async {
    if (_companies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: You must add at least one company!',
              style: TextStyle(color: Colors.white),
            ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      _loadingProvider.startLoading();

      // Upload companies data
      for (var company in _companies) {
        String? logoUrl;
        if (company['logo'] != null) {
          logoUrl = await _uploadFile(company['logo'] as XFile, 'company-logos');
        }

        await _supabase.from('companies').insert({
          'course_id': widget.courseId,
          'name': company['name'],
          'description': company['description'],
          'link': company['link'],
          'logo_url': logoUrl,
        });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Companies uploaded successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait for the message to appear before navigating back
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);

    } catch (e) {
      debugPrint('Error occurred: ${e.toString()}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _loadingProvider.stopLoading();
    }
  }

  Widget _buildImagePreview(XFile? file) {
    if (file == null) return const SizedBox.shrink();

    if (kIsWeb) {
      return Image.network(
        file.path,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(file.path),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _loadingProvider,
      child: Consumer<LoadingProvider>(
        builder: (context, loadingProvider, child) {
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text('إضافة شركات للكورس'),
                  centerTitle: true,
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إضافة شركات للكورس',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),

                      // اسم الشركة
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الشركة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // وصف الشركة
                      TextFormField(
                        controller: _companyDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'وصف الشركة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // رابط الشركة
                      TextFormField(
                        controller: _companyLinkController,
                        decoration: const InputDecoration(
                          labelText: 'رابط الشركة',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),

                      // شعار الشركة
                      const Text('شعار الشركة:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _pickCompanyLogo,
                            child: const Text('اختر شعار'),
                          ),
                          const SizedBox(width: 16),
                          if (_companyLogo != null)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _buildImagePreview(_companyLogo),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // زر إضافة شركة
                      Center(
                        child: ElevatedButton(
                          onPressed: _addCompany,
                          child: const Text('إضافة شركة'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // قائمة الشركات المضافة
                      if (_companies.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الشركات المضافة:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _companies.length,
                              itemBuilder: (context, index) {
                                final company = _companies[index];
                                return Card(
                                  child: ListTile(
                                    leading: company['logo'] != null
                                        ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _buildImagePreview(company['logo']),
                                    )
                                        : const Icon(Icons.business),
                                    title: Text(company['name']),
                                    subtitle: Text(company['description'] ?? ''),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          _companies.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),

                      // زر حفظ الشركات
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitCompanies,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('حفظ الشركات', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (loadingProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}