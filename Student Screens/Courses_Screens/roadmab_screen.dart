import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoadmapScreen extends StatefulWidget {
  final int courseId;

  const RoadmapScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _RoadmapScreenState createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  bool isLoading = true;
  String? errorMessage;
  String? roadmapImageUrl;

  @override
  void initState() {
    super.initState();
    fetchCourseData();
  }

  Future<void> fetchCourseData() async {
    try {
      final response = await Supabase.instance.client
          .from('courses')
          .select()
          .eq('id', widget.courseId)
          .maybeSingle();

      if (response == null || response['roadmap_images'] == null || response['roadmap_images'].isEmpty) {
        setState(() {
          errorMessage = 'No roadmap available.';
          isLoading = false;
        });
      } else {
        setState(() {
          roadmapImageUrl = response['roadmap_images'][0];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load roadmap.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Roadmap',
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFF2252A1)), // to color the back arrow
        elevation: 0,
      ),

      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : errorMessage != null
            ? Text(errorMessage!)
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              roadmapImageUrl!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}