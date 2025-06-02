import 'package:flutter/material.dart';
import '/Company Screens/HomeScreen.dart';
import '/Company Screens/Agreement_Screen.dart';
import '/Company Screens/History_Screen.dart';
import '/Company Screens/Profile_Screen.dart';
import '/Company Screens/nav_bar.dart';
import 'add_screen.dart'; // Import the add screen
class MainCompany extends StatefulWidget {
  static const String routeName = '/MainCompany';
  final String companyId;

  const MainCompany({Key? key, required this.companyId}) : super(key: key); // تم إضافة key هنا

  @override
  _MainCompanyState createState() => _MainCompanyState();
}

class _MainCompanyState extends State<MainCompany> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeScreen(companyid: widget.companyId), // تمرير companyId إلى HomeScreen
      AgreementScreen(),
      HistoryScreen(companyid: widget.companyId),
      ProfileScreen(companyId: widget.companyId), // تمرير companyId إلى ProfileScreen
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF196AB3),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScreen(Id: widget.companyId), // تمرير companyId
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Nav_Bar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
