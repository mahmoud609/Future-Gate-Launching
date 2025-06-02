import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Add_screens/add_admins_screen.dart';
import 'edit_admin_screen.dart';


class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final CollectionReference _adminCollection =
  FirebaseFirestore.instance.collection('admin');

  void _deleteAdmin(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this admin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () async {
              await _adminCollection.doc(docId).delete();
              Navigator.pop(context);
              _showMessage();
            },
            child: Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Admin deleted successfully"),
        backgroundColor: Color(0xFF196AB3),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Admins",
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _adminCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final adminsList = snapshot.data!.docs;

            return ListView.builder(
              itemCount: adminsList.length,
              itemBuilder: (context, index) {
                final doc = adminsList[index];
                final data = doc.data() as Map<String, dynamic>;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.admin_panel_settings,
                          size: 30, color: Colors.blue),
                    ),
                    title: Text(
                      "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email: ${data['email'] ?? ''}",
                            style: TextStyle(color: Colors.grey[700])),
                        Text("Phone: ${data['phone'] ?? ''}",
                            style: TextStyle(color: Colors.grey[700])),
                        Text("Role: ${data['role'] ?? ''}",
                            style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditAdminScreen(adminId: doc.id),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAdmin(doc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddAdminScreen()), // Changed to AddAdminScreen
          );
        },
        backgroundColor: Color(0xFF2252A1),
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.endFloat,
    );
  }
}