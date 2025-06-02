import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Onboarding_Screens/Onboarding.dart';
import '/Student Screens/Auth/login_screen.dart';
import '/Student Screens/Features/main_student.dart';
import '/Company Screens/main_company.dart';
import '/Adminscreens/Features/Admin-MS.dart';
import './Auth/auth_service.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = "SplashScreen";

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Setup animation for splash screen
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Check login status after animation completes
    Timer(Duration(seconds: 2), () {
      _checkLoginStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    bool isFirstLaunch = await _isFirstLaunch();

    if (isFirstLaunch) {
      // First time launching the app - show onboarding
      _navigateToOnboarding();
    } else {
      // Check if user is logged in
      bool isLoggedIn = await _authService.isUserLoggedIn();

      if (isLoggedIn) {
        // User is logged in - navigate to appropriate screen
        _navigateToUserScreen();
      } else {
        // User is not logged in - navigate to login screen
        _navigateToLogin();
      }
    }
  }

  Future<bool> _isFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      // Set the flag to false for future app launches
      await prefs.setBool('isFirstLaunch', false);
    }

    return isFirstLaunch;
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _navigateToUserScreen() async {
    await _authService.navigateToUserScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(
            'assets/images/splash screen img.jpg',
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print("Error loading splash image: $error");
              return Container(
                color: Colors.blue.shade100,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 80,
                    color: Colors.blue.shade800,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}