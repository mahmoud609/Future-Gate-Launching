import 'package:flutter/material.dart';
import 'Onboarding_1.dart';
import 'Onboarding_2.dart';
import 'Onboarding_3.dart';
import 'Onboarding_4.dart';
import 'Onboarding_5.dart';
import '/Student Screens/Auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            children: [
              Onboarding_1(controller: _controller),
              Onboarding_2(controller: _controller),
              Onboarding_3(controller: _controller),
              Onboarding_4(controller: _controller),
              Onboarding_5(controller: _controller),
            ],
          ),

          // Next Button at the bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Next Button
                GestureDetector(
                  onTap: () {
                    if (currentIndex < 4) {
                      _controller.nextPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // الانتقال إلى الشاشة الرئيسية عند آخر صفحة
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: (currentIndex + 1) / 5, // تحكم في التقدم
                          strokeWidth: 4,
                          backgroundColor: Colors.blue.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentIndex < 4 ? Icons.arrow_forward_ios : Icons.check,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}