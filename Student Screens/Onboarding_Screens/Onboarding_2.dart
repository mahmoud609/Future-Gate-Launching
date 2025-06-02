import 'package:flutter/material.dart';
import 'Onboarding_3.dart';

class Onboarding_2 extends StatelessWidget {
  final PageController controller;

  Onboarding_2({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 3),

              Image.asset(
                'assets/images/onboarding2.jpg',
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width * 0.8,
              ),

              SizedBox(height: 20),

              Text(
                "Welcome to",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              Text(
                "Future Gate Application",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              SizedBox(height: 10),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "We help students become job-ready by providing support with internships, CV optimization, courses, and career roadmaps.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              ),

              SizedBox(height: 20),
              Spacer(flex: 3),
            ],
          ),
        ],
      ),
    );
  }
}
