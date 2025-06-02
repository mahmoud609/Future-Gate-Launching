import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project/Student%20Screens/Features/Assessment/services/AuthService.dart';
import 'package:project/Student%20Screens/Features/Assessment/services/FirebaseService.dart';
import 'package:provider/provider.dart';
import 'screens/AssessmentListScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(AssessmentApp());
}

class AssessmentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirebaseService()), // تم إضافة FirebaseService هنا
      ],
      child: MaterialApp(
        title: 'Modern Quiz App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Color(0xFFF6F8FF),
          fontFamily: 'Poppins',
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Color(0xFF4361EE)),
            titleTextStyle: TextStyle(
              color: Color(0xFF212529),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF4361EE),
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: AssessmentListScreen(),
      ),
    );
  }
}