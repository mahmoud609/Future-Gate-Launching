import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

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
          "Help & Support",
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Future Gate Policies & Terms",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2252A1),
                ),
              ),
            ),

            // Policy Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPolicySection(
                    "Privacy Policy",
                    "At Future Gate, your privacy is our top priority. We only collect the data needed to provide the best experience for university students. This includes personal information like name, university, faculty, and preferences to help us customize content and recommendations.",
                    Icons.security,
                  ),
                  SizedBox(height: 20),
                  _buildPolicySection(
                    "Data Usage",
                    "We do not share your personal information with any third party. Your data is stored securely and is only used within app features such as course tracking, internship applications, and resume analysis using ATS tools.",
                    Icons.data_usage,
                  ),
                  SizedBox(height: 20),
                  _buildPolicySection(
                    "Contact Us",
                    "If you have any questions about our privacy policy, feel free to contact our support team through this page.",
                    Icons.contact_support,
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // FAQ Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Color(0xFF2252A1), size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Frequently Asked Questions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2252A1),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildFaqItem(
                    "How can I update my profile?",
                    "You can update your profile by going to the profile tab and clicking on 'Edit Profile'.",
                  ),
                  _buildFaqItem(
                    "How do I track my progress?",
                    "Your progress is automatically tracked when you complete courses and quizzes. You can find it under 'My Progress'.",
                  ),
                  _buildFaqItem(
                    "Can I delete my account?",
                    "Yes, you can request account deletion by contacting support. Your data will be securely removed.",
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Social Media Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.share, color: Color(0xFF2252A1), size: 24),
                        SizedBox(width: 10),
                        Text(
                          "Follow Us",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2252A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialBox(
                        context,
                        imagePath: 'assets/images/Facebook.png',
                        label: 'Facebook',
                        url: 'https://www.facebook.com/share/1AHtX3wnAu/',
                      ),
                      _buildSocialBox(
                        context,
                        imagePath: 'assets/images/Instagram.png',
                        label: 'Instagram',
                        url: 'https://www.instagram.com/future_gate990?igsh=dWhiZ3lldnZxaXd0',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF2252A1), size: 22),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2252A1),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          iconColor: Color(0xFF2252A1),
          collapsedIconColor: Color(0xFF2252A1),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBox(BuildContext context,
      {required String imagePath,
        required String label,
        required String url}) {
    return GestureDetector(
      onTap: () => _launchURL(context, url),
      child: Container(
        width: 140,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFF2252A1), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 40),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF2252A1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      await launch(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: $url')),
      );
    }
  }
}
