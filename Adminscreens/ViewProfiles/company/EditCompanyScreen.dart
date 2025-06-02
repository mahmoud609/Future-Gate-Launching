import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class EditCompanyScreen extends StatefulWidget {
  final String companyId;
  const EditCompanyScreen({Key? key, required this.companyId}) : super(key: key);

  @override
  _EditCompanyScreenState createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _websiteController;
  bool isLoading = false;
  bool _showMessage = false;
  bool _isSuccess = false;
  String _messageText = '';

  File? _companyImage;
  Uint8List? _webImage;
  String? _currentImageUrl;
  bool _hasExistingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _websiteController = TextEditingController();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    final doc = await FirebaseFirestore.instance
        .collection('company')
        .doc(widget.companyId)
        .get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['CompanyName'] ?? '';
      _descController.text = data['Description'] ?? '';
      _emailController.text = data['Email'] ?? '';
      _passwordController.text = data['Password'] ?? '';
      _websiteController.text = data['Website'] ?? '';
    }

    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('companies_profile')
        .select('img_url')
        .eq('company_id', widget.companyId)
        .maybeSingle();

    if (!mounted) return;
    setState(() {
      _currentImageUrl = response?['img_url'];
      _hasExistingImage =
          _currentImageUrl != null && _currentImageUrl!.isNotEmpty;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _companyImage = null;
        });
      } else {
        setState(() {
          _companyImage = File(picked.path);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _updateCompany() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      // Update Firestore data
      await FirebaseFirestore.instance
          .collection('company')
          .doc(widget.companyId)
          .update({
        'CompanyName': _nameController.text,
        'Description': _descController.text,
        'Email': _emailController.text,
        'Password': _passwordController.text,
        'Website': _websiteController.text,
      });

      // Handle image upload/update if a new image was selected
      if (_companyImage != null || _webImage != null) {
        final supabase = Supabase.instance.client;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        final bytes = kIsWeb ? _webImage! : await _companyImage!.readAsBytes();

        // First delete old image if it exists
        if (_hasExistingImage && _currentImageUrl != null) {
          try {
            final oldFileName = _currentImageUrl!.split('/').last;
            await supabase.storage
                .from('company-profile-img')
                .remove([oldFileName]);
          } catch (e) {
            print('Error deleting old image: $e');
          }
        }

        // Upload new image to Supabase Storage
        await supabase.storage
            .from('company-profile-img')
            .uploadBinary(fileName, bytes,
            fileOptions: FileOptions(contentType: 'image/png'));

        // Generate public URL
        final imageUrl = supabase.storage
            .from('company-profile-img')
            .getPublicUrl(fileName);

        // Update profile table
        await supabase.from('companies_profile').upsert({
          'company_id': widget.companyId,
          'img_url': imageUrl
        });

        if (!mounted) return;
        setState(() {
          _currentImageUrl = imageUrl;
          _hasExistingImage = true;
        });
      }

      // Show success message
      setState(() {
        isLoading = false;
        _showMessage = true;
        _isSuccess = true;
        _messageText = "Company updated successfully";
      });

      // Hide message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showMessage = false;
          });
          Navigator.pop(context);
        }
      });

    } catch (e) {
      // Show error silently (no message shown)
      setState(() {
        isLoading = false;
        _showMessage = true;
        _isSuccess = false;
        _messageText = "Failed to update company";
      });

      // Hide message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showMessage = false;
          });
        }
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false,
        int maxLines = 1,
        IconData? icon,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon ?? Icons.edit, color: Colors.blue),
          labelStyle: TextStyle(color: Colors.blue),
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    Widget imageWidget;
    if (_companyImage != null) {
      imageWidget = Image.file(_companyImage!, fit: BoxFit.cover);
    } else if (_webImage != null) {
      imageWidget = Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (_currentImageUrl != null) {
      imageWidget = Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    } else {
      imageWidget = Icon(Icons.image, size: 50, color: Colors.blue);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: ClipOval(
            child: imageWidget,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                _hasExistingImage ? Icons.camera_alt : Icons.add_a_photo,
                color: Colors.blue,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Company Account",
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(child: _buildImagePicker()),
                    SizedBox(height: 30),
                    _buildTextField("Company Name", _nameController,
                        icon: Icons.business,
                        validator: (v) =>
                        v!.isEmpty ? 'Required' : null),
                    _buildTextField("Description", _descController,
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (v) =>
                        v!.isEmpty ? 'Required' : null),
                    _buildTextField("Email", _emailController,
                        icon: Icons.email,
                        validator: (v) =>
                        v!.isEmpty ? 'Required' : null),
                    _buildTextField("Password", _passwordController,
                        icon: Icons.lock,
                        obscure: true,
                        validator: (v) =>
                        v!.isEmpty ? 'Required' : null),
                    _buildTextField("Website", _websiteController,
                        icon: Icons.link,
                        validator: (v) =>
                        v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _updateCompany,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2252A1),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Save Changes",
                            style: TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),

          // Custom Floating Message
          if (_showMessage)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[800] : Colors.red[800],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error_outline,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      _messageText,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}