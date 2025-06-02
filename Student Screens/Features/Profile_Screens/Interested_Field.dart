import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterestedField extends StatefulWidget {
  @override
  _InterestedFieldState createState() => _InterestedFieldState();
}

class _InterestedFieldState extends State<InterestedField> {
  final List<String> fields = [
    'Artificial Intelligence',
    'Cloud Computing',
    'Cyber Security',
    'Data Analysis',
    'Data Science',
    'Embedded Systems',
    'Game Development',
    'Graphic Designer',
    'Internet Of Things (IOT)',
    'IT Project Management',
    'IT Support',
    'Machine Learning (ML)',
    'Mobile Application Development',
    'Network Management',
    'Software Development',
    'Systems Administration',
    'UI/UX Design',
    'Web Development',
  ];

  List<String> selectedFields = [];
  bool isEditing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserFields();
  }

  Future<void> fetchUserFields() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('User_Field')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('Interested_Fields')) {
        selectedFields = List<String>.from(doc['Interested_Fields']);
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _toggleSelection(String field) {
    setState(() {
      if (selectedFields.contains(field)) {
        selectedFields.remove(field);
      } else {
        if (selectedFields.length < 3) {
          selectedFields.add(field);
        }
      }
    });
  }

  // 🔥 نفس الدالة من صفحة ChangePassword
  Future<void> _showCustomDialog(
      BuildContext context,
      String title,
      String message,
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
              // أيقونة
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
                onPressed: () {
                  Navigator.of(context).pop();
                  if (title == 'Success') {
                    Navigator.pop(context); // العودة للصفحة السابقة
                  }
                },
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

  Future<void> _saveFields() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('User_Field')
            .doc(user.uid)
            .set({
          'Interested_Fields': selectedFields,
          'userId': user.uid,
        });

        // ✨ استخدام نفس تصميم الرسالة من ChangePassword
        await _showCustomDialog(
          context,
          'Success',
          'Fields saved successfully!',
          Colors.green,
        );
      }
    } catch (e) {
      await _showCustomDialog(
        context,
        'Error',
        'Failed to save fields. Please try again.',
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2252A1))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select Interested Fields',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2252A1)),
        ),
        iconTheme: IconThemeData(color: Color(0xFF2252A1)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isEditing ? buildSelectionView() : buildDisplayView(),
      ),
    );
  }

  // View when fields are already selected
  Widget buildDisplayView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select up to 3 fields:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        if (selectedFields.isEmpty)
          Text("You haven't selected any fields yet."),
        ...selectedFields.map((field) => ListTile(
          leading: Icon(Icons.check, color: Color(0xFF2252A1)),
          title: Text(field),
        )),
        Spacer(),
        Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2252A1),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Edit", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // View when editing fields
  Widget buildSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select up to 3 fields you're interested in:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              String field = fields[index];
              bool isSelected = selectedFields.contains(field);
              return ListTile(
                onTap: () => _toggleSelection(field),
                title: Text(
                  field,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: Color(0xFF2252A1))
                    : Icon(Icons.circle_outlined, color: Colors.grey),
              );
            },
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: selectedFields.isNotEmpty ? _saveFields : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2252A1),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}