import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'Change_Password.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    // تحقق من حالة صلاحيات الإشعارات
    final status = await OneSignal.Notifications.permission;
    setState(() {
      _notificationEnabled = status;
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (enabled) {
      // طلب تفعيل الإشعارات
      final result = await OneSignal.Notifications.requestPermission(true);
      setState(() {
        _notificationEnabled = result;
      });
    } else {
      setState(() {
        _notificationEnabled = false;
      });

      // يمكنك إضافة رسالة توجيهية للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please disable notifications from app settings'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          children: [
            SizedBox(height: 20),

            // إعداد الإشعارات
            _buildSettingItem(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              isSwitch: true,
              value: _notificationEnabled,
              onChanged: _toggleNotifications,
            ),

            // باقي العناصر...
            _buildSettingItem(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePassword()),
                );
              },
            ),

            _buildSettingItem(
              icon: Icons.language_outlined,
              title: 'Language',
              onTap: () {
                Navigator.pushNamed(context, '/language');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    bool isSwitch = false,
    bool value = false,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF2252A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Color(0xFF2252A1),
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: isSwitch
              ? Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF2252A1),
          )
              : Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: Colors.grey[600],
          ),
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[200],
        ),
      ],
    );
  }
}

class Change_Password extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Color(0xFF2252A1),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Logic to change password
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2252A1),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                'Change Password',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
