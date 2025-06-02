import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class EditAdminScreen extends StatefulWidget {
  final String adminId;
  const EditAdminScreen({Key? key, required this.adminId}) : super(key: key);

  @override
  _EditAdminScreenState createState() => _EditAdminScreenState();
}

class _EditAdminScreenState extends State<EditAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? selectedRole;
  List<String> selectedPermissions = [];

  bool isLoading = false;
  bool _showMessage = false;
  bool _isSuccess = false;
  String _messageText = '';

  File? _adminImage;
  Uint8List? _webImage;
  String? _currentImageUrl;
  bool _hasExistingImage = false;

  final List<String> roles = [
    'Super Admin',
    'Content Admin',
    'User Admin',
    'Internship Admin',
    'Support Admin',
    'Company Admin'
  ];

  final List<String> allPermissions = ['Read', 'Write', 'Edit', 'Delete'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    DocumentSnapshot doc = await _firestore.collection('admin').doc(widget.adminId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        selectedRole = data['role'] ?? '';
        selectedPermissions = List<String>.from(data['permissions'] ?? []);
      });
    }

    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('admins_profile')
        .select('img_url')
        .eq('admin_id', widget.adminId)
        .maybeSingle();

    if (!mounted) return;
    setState(() {
      _currentImageUrl = response?['img_url'];
      _hasExistingImage = _currentImageUrl != null && _currentImageUrl!.isNotEmpty;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      // تحديث بيانات المسؤول في Firestore
      await _firestore.collection('admin').doc(widget.adminId).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': selectedRole,
        'permissions': selectedPermissions,
      });

      // رفع الصورة إذا تم اختيار واحدة جديدة
      if (_adminImage != null || _webImage != null) {
        final supabase = Supabase.instance.client;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        final bytes = kIsWeb ? _webImage! : await _adminImage!.readAsBytes();

        if (_hasExistingImage && _currentImageUrl != null) {
          try {
            final oldFileName = _currentImageUrl!.split('/').last;
            await supabase.storage.from('admin-profile-img').remove([oldFileName]);
          } catch (e) {
            print('Error deleting old image: $e');
          }
        }

        await supabase.storage
            .from('admin-profile-img')
            .uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: 'image/png'));

        final imageUrl = supabase.storage.from('admin-profile-img').getPublicUrl(fileName);

        await supabase
            .from('admins_profile')
            .upsert({'admin_id': widget.adminId, 'img_url': imageUrl});

        if (mounted) {
          setState(() {
            _currentImageUrl = imageUrl;
            _hasExistingImage = true;
          });
        }
      }

      setState(() {
        isLoading = false;
        _showMessage = true;
        _isSuccess = true;
        _messageText = "Admin info updated successfully";
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showMessage = false;
          });
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _showMessage = true;
        _isSuccess = false;
        _messageText = "Failed to update admin";
      });

      Future.delayed(const Duration(seconds: 3), () {
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

  Widget _buildRoleDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
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
        hint: const Text('Select Role'),
        value: selectedRole,
        items: roles.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Row(
              children: [
                Icon(
                  role == 'Super Admin'
                      ? Icons.shield
                      : role == 'Content Admin'
                      ? Icons.edit
                      : role == 'User Admin'
                      ? Icons.people
                      : role == 'Internship Admin'
                      ? Icons.school
                      : role == 'Support Admin'
                      ? Icons.headset_mic
                      : Icons.business,
                  color: Colors.blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(role),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedRole = value;
          });
        },
        validator: (value) => value == null ? 'Please select a role' : null,
      ),
    );
  }

  Widget _buildPermissionSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showPermissionDialog(context),
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.security, color: Colors.blue),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    selectedPermissions.isEmpty
                        ? 'Select Permissions'
                        : selectedPermissions.join(', '),
                    style: TextStyle(
                      color: selectedPermissions.isEmpty ? Colors.grey : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.arrow_drop_down, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    final List<String> tempPermissions = List.from(selectedPermissions);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Permissions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2252A1)),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allPermissions.length,
                      itemBuilder: (context, index) {
                        final permission = allPermissions[index];
                        return ListTile(
                          leading: Icon(
                            permission == 'Read'
                                ? Icons.visibility
                                : permission == 'Write'
                                ? Icons.create
                                : permission == 'Edit'
                                ? Icons.edit
                                : Icons.delete,
                            color: Colors.blue,
                          ),
                          title: Text(permission),
                          trailing: Checkbox(
                            value: tempPermissions.contains(permission),
                            activeColor: Colors.blue,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value!) {
                                  tempPermissions.add(permission);
                                } else {
                                  tempPermissions.remove(permission);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (tempPermissions.contains(permission)) {
                                tempPermissions.remove(permission);
                              } else {
                                tempPermissions.add(permission);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: Navigator.of(context).pop,
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPermissions = tempPermissions;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2252A1),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagePicker() {
    Widget imageWidget;
    if (_adminImage != null) {
      imageWidget = Image.file(_adminImage!, fit: BoxFit.cover);
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
      imageWidget = Icon(Icons.person, size: 50, color: Colors.blue);
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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _adminImage = null;
        });
      } else {
        setState(() {
          _adminImage = File(picked.path);
          _webImage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Admin Account",
          style: TextStyle(
            color: const Color(0xFF2252A1),
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
                    const SizedBox(height: 30),
                    _buildTextField("First Name", _firstNameController,
                        icon: Icons.person, validator: (v) => v!.isEmpty ? 'Required' : null),
                    _buildTextField("Last Name", _lastNameController,
                        icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Required' : null),
                    _buildTextField("Email", _emailController,
                        icon: Icons.email, validator: (v) => v!.isEmpty ? 'Required' : null),
                    _buildTextField("Phone", _phoneController,
                        icon: Icons.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                    _buildRoleDropdown(),
                    _buildPermissionSelector(),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2252A1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    const SizedBox(width: 10),
                    Text(
                      _messageText,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
