import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Courses_Screens/coursecat.dart'; // دي هتعدل اسمها تحت لو عايز
import 'main_student.dart';

class CoursesScreen extends StatelessWidget {
  static const String routeName = '/CoursesScreen';
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Courses",
            style: TextStyle(
                color: Color(0xFF2252A1),
                fontSize: 22,
                fontWeight: FontWeight.bold),

          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)), // Optional: make the back arrow the same color
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
            },
          ),

        ),
        body: CustomScrollView(

          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: false,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.asset(
                  'assets/images/courses.jpeg',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Choose Your Field',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchCourses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No courses available.'));
                      } else {
                        final courses = snapshot.data!;
                        return Column(
                          children: courses.map((course) {
                            return FieldButton(
                              text: course['name'] ?? 'No Title',
                              id: course['id'],
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCourses() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('courses').select('id, name');
    return List<Map<String, dynamic>>.from(response);
  }
}

class FieldButton extends StatelessWidget {
  final String text;
  final int id;

  const FieldButton({required this.text, required this.id});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: SizedBox(
        width: 300,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseCat(courseId: id),
                ),
              );
            },
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}