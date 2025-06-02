import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// Firebase config
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// Auth
import 'Student Screens/Auth/auth_provider.dart';
import 'Student Screens/Auth/login_screen.dart';
import 'Student Screens/Auth/register_screen.dart';
import 'Student Screens/Auth/forgot_password_screen.dart';
// Services for assessment feature
import 'Student Screens/Features/Assessment/services/AuthService.dart';
import 'Student Screens/Features/Assessment/services/FirebaseService.dart';
// Screens
import 'Student Screens/splash_screen.dart';
import 'Student Screens/Features/main_student.dart';
import 'Adminscreens/Features/Admin-MS.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Firebase App Check with debug token for development
  await FirebaseAppCheck.instance.activate(
    // For Android - استخدم debug provider أثناء التطوير
    androidProvider: AndroidProvider.debug,
    // For iOS - استخدم debug provider أثناء التطوير
    appleProvider: AppleProvider.debug,
    // لا حاجة لـ webRecaptchaSiteKey في بيئة التطوير
  );
  // تفعيل تحديث التوكن تلقائيًا (مهم أثناء التطوير)
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  // Initialize Facebook SDK
  await FacebookAuth.instance.autoLogAppEventsEnabled(true);
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xafztwdrytnggitdbioc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhhZnp0d2RyeXRuZ2dpdGRiaW9jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ5MDU5ODgsImV4cCI6MjA2MDQ4MTk4OH0.Xn0b_ArBP2-sSyS9WBGHKlVUEMHMPt7FtCy5XBPtehk',
  );
  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("a7907370-789c-4b08-b75d-88a68dd2490a");
  OneSignal.Notifications.requestPermission(true);
  // Load .env variables
  await dotenv.load(fileName: "dotenv.get");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ✅ Providers الخاصة بالأسيسمنت
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirebaseService()),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => SplashScreen(),
        MainScreen.routeName: (_) => MainScreen(),
        Adminms.routeName: (_) => Adminms(),
        // Auth Screens
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => RegisterScreen(),
        ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
      },
    );
  }
}