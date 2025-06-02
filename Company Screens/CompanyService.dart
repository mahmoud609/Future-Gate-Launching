import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class CompanyService {
  // جلب companyId مباشرةً إذا كان معروفًا مسبقًا
  static Future<String?> getCompanyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user is logged in");
      return null;
    }
    // نفترض أن لكل مستخدم وثيقة في `company` بنفس الـ `uid`
    final doc = await FirebaseFirestore.instance.collection('company').doc(user.uid).get();
    if (doc.exists) {
      print("Company ID: ${doc.id}");
      return doc.id;
    } else {
      print("No company document found for user with UID: ${user.uid}");
      return null;
    }
  }
  // جلب بيانات الشركة (اسم، صورة، إلخ) بناءً على الـ companyId
  static Future<Map<String, dynamic>> getCompanyData(String companyId) async {
    if (companyId.isEmpty) {
      print("Invalid company ID");
      return {
        'CompanyName': 'Unknown Company',
        'CompanyPhoto': '',
      };
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('company').doc(companyId).get();
      final data = doc.data() ?? {}; // تجنب الأخطاء إذا لم تكن هناك بيانات
      print("Company Data: $data");
      return {
        'CompanyName': data['CompanyName'] ?? 'Unknown Company',
        'CompanyPhoto': data['CompanyPhoto'] ?? '',
      };
    } catch (e) {
      print("Error fetching company data: $e");
      return {
        'CompanyName': 'Error Loading Data',
        'CompanyPhoto': '',
      };
    }
  }
  // جلب فرص التدريب الخاصة بالشركة
  static Stream<QuerySnapshot> getInternships(String companyId) {
    if (companyId.isEmpty) {
      print("Company ID is empty");
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('interns')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }
  // جلب الوظائف الخاصة بالشركة
  static Stream<QuerySnapshot> getJobs(String companyId) {
    if (companyId.isEmpty) {
      print("Company ID is empty");
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('interns') // تأكد أن لديك مجموعة `jobs`
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }
}