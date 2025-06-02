import 'package:flutter/material.dart';

class Onboarding_1 extends StatelessWidget {
  final PageController controller;

  Onboarding_1({required this.controller});

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
              Spacer(flex: 1),
              Image.asset(
                'assets/images/onboarding11.jpg',
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width * 0.9,
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
                  "The best finder & Internship finder app where the best internship will find you",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Spacer(), // هذه السطر يساعد في محاذاة العناصر بشكل صحيح
            ],
          ),
        ],
      ),
    );
  }
}
