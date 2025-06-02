import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAdminScreen extends StatefulWidget {
  @override
  _AddAdminScreenState createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String phone = '';
  String? selectedRole;
  List<String> selectedPermissions = [];

  // أدوار المسؤولين
  final List<String> roles = [
    'Super Admin',
    'Content Admin',
    'User Admin',
    'Internship Admin',
    'Support Admin',
    'Company Admin'
  ];

  // الصلاحيات المتوفرة
  final List<String> allPermissions = ['Read', 'Write', 'Edit', 'Delete'];

  // ✅ Validation functions
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value) ? null : 'Enter a valid email';
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter password';
    return value!.length < 8 ? 'Password must be at least 8 characters' : null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Enter phone number';
    final phoneRegex = RegExp(r'^\d{11}$'); // Exactly 11 digits
    return phoneRegex.hasMatch(value!) ? null : 'Phone number must be exactly 11 digits';
  }

  Future<void> _addAdmin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // ✅ Create Firebase Authentication user
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // ✅ Save admin details to Firestore
        await FirebaseFirestore.instance
            .collection('admin')
            .doc(userCredential.user!.uid)
            .set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'role': selectedRole,
          'permissions': selectedPermissions,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Admin added successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auth error: ${e.message}'),
            backgroundColor: Colors.red[800],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add admin: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    }
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
          "Add New Admin",
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
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This page allows super admins to add new admin users to the system.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // First Name
                    _buildTextField(
                      "First Name",
                      Icons.person,
                          (value) => firstName = value!,
                      validator: (value) =>
                      value!.isEmpty ? 'Enter first name' : null,
                    ),

                    // Last Name
                    _buildTextField(
                      "Last Name",
                      Icons.person_outline,
                          (value) => lastName = value!,
                      validator: (value) =>
                      value!.isEmpty ? 'Enter last name' : null,
                    ),

                    // Email
                    _buildTextField(
                      "Email",
                      Icons.email,
                          (value) => email = value!,
                      validator: validateEmail,
                    ),

                    // Password
                    _buildTextField(
                      "Password",
                      Icons.lock,
                          (value) => password = value!,
                      obscureText: true,
                      validator: validatePassword,
                    ),

                    // Phone Number
                    _buildTextField(
                      "Phone Number",
                      Icons.phone,
                          (value) => phone = value!,
                      validator: validatePhone,
                      keyboardType: TextInputType.phone,
                    ),

                    // Role Dropdown
                    Padding(
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
                                  role == 'Super Admin' ? Icons.shield :
                                  role == 'Content Admin' ? Icons.edit :
                                  role == 'User Admin' ? Icons.people :
                                  role == 'Internship Admin' ? Icons.school :
                                  role == 'Support Admin' ? Icons.headset_mic :
                                  Icons.business,
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
                    ),

                    // Permissions Multi-Select
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _showPermissionDialog(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.security, color: Colors.blue),
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
                                      color: selectedPermissions.isEmpty
                                          ? Colors.grey
                                          : Colors.black87,
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
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2252A1),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
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
        TextInputType? keyboardType,
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
        keyboardType: keyboardType,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2252A1),
                    ),
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
                            permission == 'Read' ? Icons.visibility :
                            permission == 'Write' ? Icons.create :
                            permission == 'Edit' ? Icons.edit :
                            Icons.delete,
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
}