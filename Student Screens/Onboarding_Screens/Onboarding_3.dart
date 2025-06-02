import 'package:flutter/material.dart';
import 'Onboarding_4.dart';

class Onboarding_3 extends StatelessWidget {
  final PageController controller;

  Onboarding_3({required this.controller});

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
                'assets/images/onboarding3.jpg',
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
                  "We provide career roadmaps tailored to your track, along with market requirements and specialized courses to help you become job-ready.",
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
