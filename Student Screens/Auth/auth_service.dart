import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/Company%20Screens/main_company.dart';
import 'package:project/Student%20Screens/Features/main_student.dart';
import 'package:project/Adminscreens/Features/Admin-MS.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
// إذا كنت تستخدم storage في Supabase، قد تحتاج إلى هذه المكتبة أيضًا
import 'dart:typed_data';
// لإدارة الملفات
import 'package:path/path.dart' as path;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Keys for shared preferences
  static const String KEY_USER_EMAIL = 'user_email';
  static const String KEY_USER_TYPE = 'user_type';
  static const String KEY_COMPANY_ID = 'company_id';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_LOGIN_TIME = 'login_time';
  static const String KEY_IS_LOGGED_IN = 'is_logged_in';

  // User types
  static const String USER_TYPE_STUDENT = 'student';
  static const String USER_TYPE_COMPANY = 'company';
  static const String USER_TYPE_ADMIN = 'admin';

  // Enhanced error dialog with modern design
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20), // Side margins
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon with shadow effect
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red[400]!, Colors.red[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 25),

                // Error title
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 15),

                // Error message
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(height: 25),

                // Confirmation button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[500],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Success dialog
  static void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 15),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[500],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateUserPlayerId(String userId, String collection) async {
    String? playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      await _firestore.collection(collection).doc(userId).update({'playerId': playerId});
    }
  }

  // Save login data to SharedPreferences
  Future<void> _saveLoginData({
    required String userEmail,
    required String userType,
    String? userId,
    String? companyId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save login status
    await prefs.setBool(KEY_IS_LOGGED_IN, true);

    // Save user information
    await prefs.setString(KEY_USER_EMAIL, userEmail);
    await prefs.setString(KEY_USER_TYPE, userType);

    // Save the current timestamp for monthly auto-logout
    await prefs.setInt(KEY_LOGIN_TIME, DateTime.now().millisecondsSinceEpoch);

    // Save user ID if available
    if (userId != null) {
      await prefs.setString(KEY_USER_ID, userId);
    }

    // Save company ID if available
    if (companyId != null) {
      await prefs.setString(KEY_COMPANY_ID, companyId);
    }

    print("✅ Login data saved to SharedPreferences");
  }

  // Check if user is logged in and if a month has passed since last login
  Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(KEY_IS_LOGGED_IN) ?? false;

    if (!isLoggedIn) return false;

    // Check if a month (30 days) has passed since last login
    int loginTime = prefs.getInt(KEY_LOGIN_TIME) ?? 0;
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // Calculate the time difference in days (approximately)
    int daysPassed = (currentTime - loginTime) ~/ (1000 * 60 * 60 * 24);

    // If 30 days have passed, log out the user
    if (daysPassed >= 30) {
      await _clearLoginData();
      return false;
    }

    return true;
  }

  // Get the user type (student, company, admin)
  Future<String?> getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_TYPE);
  }

  // Get the user email
  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_EMAIL);
  }

  // Get the user ID
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_ID);
  }

  // Get the company ID
  Future<String?> getStoredCompanyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_COMPANY_ID);
  }

  // Clear login data from SharedPreferences
  Future<void> _clearLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_IS_LOGGED_IN);
    await prefs.remove(KEY_USER_EMAIL);
    await prefs.remove(KEY_USER_TYPE);
    await prefs.remove(KEY_LOGIN_TIME);
    await prefs.remove(KEY_USER_ID);
    await prefs.remove(KEY_COMPANY_ID);
    print("✅ Login data cleared from SharedPreferences");
  }

  // Navigate to appropriate screen based on user type
  Future<void> navigateToUserScreen(BuildContext context) async {
    String? userType = await getUserType();

    if (userType == USER_TYPE_STUDENT) {
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
    } else if (userType == USER_TYPE_COMPANY) {
      String? companyId = await getStoredCompanyId();
      if (companyId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainCompany(companyId: companyId),
          ),
        );
      }
    } else if (userType == USER_TYPE_ADMIN) {
      Navigator.pushReplacementNamed(context, Adminms.routeName);
    } else {
      // If user type is not found, direct to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<Map<String, dynamic>?> getCompanyById(String companyId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('company').doc(companyId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print("❌ No company found with ID: $companyId");
        return null;
      }
    } catch (e) {
      print("⚠️ Error fetching company data: $e");
      return null;
    }
  }

  Future<void> _handleLogin(String email, BuildContext context) async {
    try {
      QuerySnapshot userSnapshot = await _firestore.collection('users').where('email', isEqualTo: email).get();
      QuerySnapshot companySnapshot = await _firestore.collection('company').where('Email', isEqualTo: email).get();
      QuerySnapshot adminSnapshot = await _firestore.collection('admin').where('email', isEqualTo: email).get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        await _updateUserPlayerId(userId, 'users');

        // Save student login data
        await _saveLoginData(
          userEmail: email,
          userType: USER_TYPE_STUDENT,
          userId: userId,
        );

        Navigator.pushReplacementNamed(context, MainScreen.routeName);
      } else if (companySnapshot.docs.isNotEmpty) {
        String companyId = companySnapshot.docs.first.id;
        await _updateUserPlayerId(companyId, 'company');

        // Save company login data
        await _saveLoginData(
          userEmail: email,
          userType: USER_TYPE_COMPANY,
          companyId: companyId,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainCompany(companyId: companyId),
          ),
        );
      } else if (adminSnapshot.docs.isNotEmpty) {
        String adminId = adminSnapshot.docs.first.id;
        await _updateUserPlayerId(adminId, 'admin');

        // Save admin login data
        await _saveLoginData(
          userEmail: email,
          userType: USER_TYPE_ADMIN,
          userId: adminId,
        );

        Navigator.pushReplacementNamed(context, Adminms.routeName);
      } else {
        showErrorDialog(context, 'No account found with this email. Please register first.');
      }
    } catch (e) {
      showErrorDialog(context, 'Error checking user data: ${e.toString()}');
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _handleLogin(email, context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Please enter a valid email and password.';
      if (e.code == 'user-not-found') errorMessage = 'No account found with this email.';
      if (e.code == 'wrong-password') errorMessage = 'Incorrect password. Please try again.';
      showErrorDialog(context, errorMessage);
    } catch (e) {
      showErrorDialog(context, 'An unexpected error occurred. Please try again.');
    }
  }


  Future<void> signInWithFacebook(BuildContext context) async {
    try {
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final userData = await _facebookAuth.getUserData(
          fields: "name,email,picture.width(200)",
        );
        print("Facebook User Data: $userData");

        final String? email = userData['email'];
        final String? name = userData['name'];
        final String? pictureUrl = userData['picture']?['data']?['url'];

        if (email == null) {
          showErrorDialog(context, 'Could not get email from Facebook. Please try again.');
          return;
        }

        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user == null) {
          showErrorDialog(context, 'Failed to sign in with Facebook.');
          return;
        }

        QuerySnapshot userSnapshot = await _firestore.collection('users').where('email', isEqualTo: email).get();

        if (userSnapshot.docs.isNotEmpty) {
          // Existing user
          String userId = userSnapshot.docs.first.id;
          await _updateUserPlayerId(userId, 'users');

          // Save student login data
          await _saveLoginData(
            userEmail: email,
            userType: USER_TYPE_STUDENT,
            userId: userId,
          );

          Navigator.pushReplacementNamed(context, MainScreen.routeName);
        } else {
          // New user - create account and save profile image to Supabase
          String userId = user.uid;

          // Save profile image to Supabase if available
          String? supabaseImageUrl;
          if (pictureUrl != null) {
            supabaseImageUrl = await _saveProfileImageToSupabase(pictureUrl, userId);
          }

          // Create user document in Firebase
          await _firestore.collection('users').doc(userId).set({
            'email': email,
            'firstName': name,
            'photoURL': pictureUrl, // Original Facebook photo URL
            'supabasePhotoURL': supabaseImageUrl, // Add Supabase image URL if available
            'registrationMethod': 'facebook',
            'createdAt': FieldValue.serverTimestamp(),
            'playerId': OneSignal.User.pushSubscription.id,
            'userType': 'student',
            'isProfileComplete': false,
          });

          await _updateUserPlayerId(userId, 'users');

          // Save student login data
          await _saveLoginData(
            userEmail: email,
            userType: USER_TYPE_STUDENT,
            userId: userId,
          );

          Navigator.pushReplacementNamed(context, MainScreen.routeName);
        }
      } else if (result.status == LoginStatus.cancelled) {
        showErrorDialog(context, 'Facebook login was cancelled');
      } else {
        showErrorDialog(context, 'Facebook login failed: ${result.message}');
      }
    } catch (e) {
      print('Facebook Sign-In error: $e');
      showErrorDialog(context, 'Facebook Sign-In failed: ${e.toString()}');
    }
  }
// This function downloads the image from Facebook and uploads it to Supabase

  Future<String?> _saveProfileImageToSupabase(String imageUrl, String userId) async {
    try {
      final supabaseClient = Supabase.instance.client;

      // 1. تحميل الصورة من Facebook
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print('Failed to download image: ${response.statusCode}');
        return null;
      }

      final bytes = response.bodyBytes;
      final String fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 2. رفع الصورة إلى Supabase Storage
      final uploadPath = await supabaseClient.storage
          .from('profile-images')
          .uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      if (uploadPath.isEmpty) {
        print('Failed to upload image to Supabase.');
        return null;
      }

      // 3. الحصول على رابط الصورة العام
      final String publicUrl = supabaseClient.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      // 4. تخزين البيانات في جدول profile_images
      final insertResponse = await supabaseClient
          .from('profile_images')
          .insert({
        'image_url': publicUrl,
        'user_id': userId,
      });

      if (insertResponse.error != null) {
        print('Error inserting into profile_images table: ${insertResponse.error!.message}');
      }

      return publicUrl;

    } catch (e) {
      print('Error saving profile image to Supabase: $e');
      return null;
    }
  }

  Future<void> createNewUserAccount(User? user) async {
    if (user == null) return;

    // Check if the user has a photoURL (which might be the case with social logins)
    String? supabaseImageUrl;
    if (user.photoURL != null) {
      supabaseImageUrl = await _saveProfileImageToSupabase(user.photoURL!, user.uid);
    }

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'supabasePhotoURL': supabaseImageUrl, // Add the Supabase image URL
      'createdAt': FieldValue.serverTimestamp(),
      'playerId': OneSignal.User.pushSubscription.id,
      'userType': 'student',
      'isProfileComplete': false,
    });

    // Save student login data
    if (user.email != null) {
      await _saveLoginData(
        userEmail: user.email!,
        userType: USER_TYPE_STUDENT,
        userId: user.uid,
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _facebookAuth.logOut();
      await _auth.signOut();
      await _clearLoginData();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      showErrorDialog(context, 'Error signing out: ${e.toString()}');
    }
  }

  // Check login session validity and refresh if needed
  Future<void> refreshLoginSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int loginTime = prefs.getInt(KEY_LOGIN_TIME) ?? 0;

    // Update the login time to extend the session
    await prefs.setInt(KEY_LOGIN_TIME, DateTime.now().millisecondsSinceEpoch);
    print("✅ Login session refreshed");
  }

  // Automatically log out if a month has passed
  Future<bool> checkAndHandleAutoLogout(BuildContext context) async {
    bool isLoggedIn = await isUserLoggedIn();
    if (!isLoggedIn) {
      // User is not logged in or session has expired
      await signOut(context);
      return false;
    }

    // Refresh the login session
    await refreshLoginSession();
    return true;
  }
}