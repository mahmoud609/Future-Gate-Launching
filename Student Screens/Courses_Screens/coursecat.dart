import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'roadmab_screen.dart';


class CourseCat extends StatefulWidget {
  static const String routeName = "coursecat";

  final int courseId;
  const CourseCat({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseCat> createState() => _CourseCatState();
}

class _CourseCatState extends State<CourseCat> {
  late Future<Map<String, dynamic>?> _courseFuture;
  late Future<List<Map<String, dynamic>>> _companiesFuture;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _courseFuture = fetchCourse(widget.courseId).then((course) {
      if (course != null && course['video_url'] != null && course['video_url'].isNotEmpty) {
        _initializeVideoPlayer(course['video_url']);
      }
      return course;
    });
    _companiesFuture = fetchCompanies(widget.courseId);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> fetchCourse(int courseId) async {
    final response = await Supabase.instance.client
        .from('courses')
        .select()
        .eq('id', courseId)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> fetchCompanies(int courseId) async {
    final response = await Supabase.instance.client
        .from('companies')
        .select()
        .eq('course_id', courseId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }

    _videoController = VideoPlayerController.network(videoUrl)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    await _videoController!.initialize();
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  void _toggleVideoPlay() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _courseFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!['name'],
                style: TextStyle(
                  color: Color(0xFF2252A1),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return Text(
              'Course',
              style: TextStyle(
                color: Color(0xFF2252A1),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        iconTheme: IconThemeData(color: Color(0xFF2252A1),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(

        future: _courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading course"));
          }
          if (!snapshot.hasData) {
            return Center(child: Text("Course not found"));
          }

          final course = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Roadmap Image
                if (course['image_url'] != null && course['image_url'].isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      /*border: Border.all(color: Color(0xFF196AB3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],*/
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        course['image_url'], // remove [0]
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),


                SizedBox(height: 16),

                // 2. Description

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    course['description'],
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 20),


                // Icon and Video Section
                Row(
                  children: [
                    Icon(
                      Icons.video_library,
                      color: Color(0xFF196AB3),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Watch Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF196AB3),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // 3. Video
                if (course['video_url'] != null && course['video_url'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0,),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: GestureDetector(
                        onTap: _toggleVideoPlay,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isVideoInitialized)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: VideoPlayer(_videoController!),
                                ),

                              if (!_isVideoInitialized)
                                Center(child: CircularProgressIndicator()),

                              if (!_isVideoPlaying && _isVideoInitialized)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 25),

                // 4. Roadmap Button (moved here)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Roadmap Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoadmapScreen(courseId: widget.courseId)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF196AB3),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore Roadmap',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32), // Added more space before
                Text(
                  'Places to Learn ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF196AB3),
                  ),
                ),
                SizedBox(height: 32),


                // 5. Companies section
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _companiesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error loading companies"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text("No companies available.");
                    }

                    return Column(
                      children: snapshot.data!
                          .map((company) => CourseCard(
                        logoUrl: company['logo_url'],
                        title: company['name'],
                        subtitle: company['type'] ?? 'Online Course',
                        link: company['link'],
                      ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),

          );
        },
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final String? logoUrl;
  final String title;
  final String subtitle;
  final String? link;

  const CourseCard({
    required this.logoUrl,
    required this.title,
    required this.subtitle,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF196AB3), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                if (logoUrl != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        logoUrl!,
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 30,
                      color: Color(0xFF196AB3),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (link != null && await canLaunchUrl(Uri.parse(link!))) {
                  await launchUrl(Uri.parse(link!));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF196AB3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/images/tap.png',
                    height: 24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}