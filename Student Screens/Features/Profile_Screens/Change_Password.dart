import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User user;

  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // متغيرات لإظهار/إخفاء كلمات المرور
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser!;
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // إعادة المصادقة
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // تحديث كلمة المرور
        await user.updatePassword(newPasswordController.text);

        // عرض رسالة نجاح
        await _showCustomDialog(
          context,
          'Success',
          'Password changed successfully!',
          'assets/images/success_icon.png', // يمكنك استبدالها بأيقونة النجاح الخاصة بك
          Colors.green,
        );

        // بعد إغلاق الرسالة، العودة للصفحة السابقة
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // عرض رسالة خطأ
        await _showCustomDialog(
          context,
          'Error',
          'Failed to change password. Make sure the old password is correct.',
          'assets/images/error_icon.png', // يمكنك استبدالها بأيقونة الخطأ الخاصة بك
          Colors.red,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// دالة معدلة لعرض الرسائل بشكل أجمل
  Future<void> _showCustomDialog(
      BuildContext context,
      String title,
      String message,
      String iconPath,
      Color color,
      ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة (يمكن استبدالها بصورة أو استخدام أيقونة Material)
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  title == 'Success' ? Icons.check_circle : Icons.error,
                  color: color,
                  size: 50,
                ),
              ),
              SizedBox(height: 15),
              // العنوان
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 10),
              // الرسالة
              Text(
                message,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // زر التأكيد
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2252A1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Change Password",
          style: TextStyle(
              color: Color(0xFF2252A1),
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // كلمة المرور القديمة
                TextFormField(
                  controller: oldPasswordController,
                  decoration: _inputDecoration(
                    "Old Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _oldPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _oldPasswordVisible = !_oldPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_oldPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your old password";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 10),

                // كلمة المرور الجديدة
                TextFormField(
                  controller: newPasswordController,
                  decoration: _inputDecoration(
                    "New Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _newPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _newPasswordVisible = !_newPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_newPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a new password";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 10),

                // تأكيد كلمة المرور
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: _inputDecoration(
                    "Confirm Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your new password";
                    }
                    if (value != newPasswordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 20),

                // زر التحديث
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: Color(0xFF2252A1)))
                    : ElevatedButton.icon(
                  onPressed: _changePassword,
                  label: Text(
                    "Change Password",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2252A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}