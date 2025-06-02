import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCompanyScreen extends StatefulWidget {
  @override
  _AddCompanyScreenState createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  String companyName = '';
  String description = '';
  String email = '';
  String password = '';
  String website = '';
  File? _companyImage;
  Uint8List? _webImage;
  bool isLoading = false;
  bool _showSuccessMessage = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          pickedFile.readAsBytes().then((value) {
            _webImage = value;
            _companyImage = null;
          });
        } else {
          _companyImage = File(pickedFile.path);
          _webImage = null;
        }
      });
    }
  }

  Future<void> _addCompany() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      _formKey.currentState!.save();

      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final userId = credential.user!.uid;

        await FirebaseFirestore.instance.collection('company').doc(userId).set({
          'CompanyID': userId,
          'CompanyName': companyName,
          'Description': description,
          'Email': email,
          'Website': website,
        });

        if (_companyImage != null || _webImage != null) {
          final supabase = Supabase.instance.client;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
          final bytes = kIsWeb ? _webImage! : await _companyImage!.readAsBytes();
          final storageResponse = await supabase.storage
              .from('company-profile-img')
              .uploadBinary(fileName, bytes);
          if (storageResponse.isEmpty) throw Exception('Image upload failed.');

          final imageUrl = supabase.storage
              .from('company-profile-img')
              .getPublicUrl(fileName);

          await supabase.from('companies_profile').insert({
            'img_url': imageUrl,
            'company_id': userId,
          });
        }

        // Show success message
        setState(() {
          isLoading = false;
          _showSuccessMessage = true;
        });

        // Hide message after 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            _showSuccessMessage = false;
          });
          Navigator.pop(context);
        });

      } catch (e) {
        setState(() {
          isLoading = false;
        });
        // Silently fail - no error message shown
      }
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter password';
    if (value.length < 8) return 'Password must be at least 8 characters long';
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    if (!hasUppercase) return 'Password must contain at least one uppercase letter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add New Company",
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This page allows admins to add new companies to the application.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Center(child: _buildImagePicker()),
                    _buildTextField(
                      "Company Name",
                      Icons.business,
                          (value) => companyName = value!,
                      validator: (value) => value!.isEmpty ? 'Enter company name' : null,
                    ),
                    _buildTextField(
                      "Description",
                      Icons.description,
                          (value) => description = value!,
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Enter description' : null,
                    ),
                    _buildTextField(
                      "Email",
                      Icons.email,
                          (value) => email = value!,
                      validator: validateEmail,
                    ),
                    _buildTextField(
                      "Password",
                      Icons.lock,
                          (value) => password = value!,
                      obscureText: true,
                      validator: validatePassword,
                    ),
                    _buildTextField(
                      "Website",
                      Icons.link,
                          (value) => website = value!,
                      validator: (value) => value!.isEmpty ? 'Enter website' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _addCompany,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2252A1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Submit", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Custom success message
          if (_showSuccessMessage)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Company added successfully",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      IconData icon,
      Function(String?) onSaved, {
        int maxLines = 1,
        bool obscureText = false,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.blue),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        maxLines: maxLines,
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: _companyImage != null || _webImage != null
                ? ClipOval(
              child: kIsWeb
                  ? Image.memory(_webImage!, fit: BoxFit.cover, width: 120, height: 120)
                  : Image.file(_companyImage!, fit: BoxFit.cover, width: 120, height: 120),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.image, size: 40, color: Colors.blue),
                Text("Upload Image", style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}