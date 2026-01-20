import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_purple_basket/Admin/notification/admin_notification_page.dart';
import 'package:flutter_purple_basket/Auth/signin.dart';
import 'package:flutter_purple_basket/Admin/category/readcat.dart';
import 'package:flutter_purple_basket/Admin/dashboard.dart';
import 'package:flutter_purple_basket/Admin/order/readorder.dart';
import 'package:flutter_purple_basket/Admin/product/readproduct.dart';
import 'package:flutter_purple_basket/Admin/user/readuser.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? appBarActions; // optional actions

  const AdminLayout({
    super.key,
    required this.child,
    this.title = "Dashboard",
    this.appBarActions,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String userName = "Admin";
  String userEmail = "admin@purplebasket.com";
  Uint8List? userImageBytes;

  final Color _sidebarColor = const Color.fromARGB(255, 148, 44, 161);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('User').doc(currentUser.uid).get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc.get('User Name') ?? userName;
            userEmail = userDoc.get('User Email') ?? userEmail;

            String imgStr = userDoc.get('User Image') ?? '';
            if (imgStr.isNotEmpty) userImageBytes = base64Decode(imgStr);
          });
        }
      } catch (e) {
        debugPrint("Error loading user: $e");
      }
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: widget.appBarActions ?? [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_outlined, color: Colors.grey),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: widget.child,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _sidebarColor,
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: userImageBytes != null ? MemoryImage(userImageBytes!) : null,
                    child: userImageBytes == null
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis),
                        Text(userEmail,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _drawerItemWidget(Icons.dashboard_rounded, "Dashboard", const AdminDashboard()),
                  _drawerItemWidget(Icons.category_rounded, "Categories", const ReadCategoryScreen()),
                  _drawerItemWidget(Icons.shopping_bag_outlined, "Products", const ReadProductScreen()), 
                  _drawerItemWidget(Icons.shopping_cart_outlined, "Orders", const AdminOrdersScreen()),
                  _drawerItemWidget(Icons.group_rounded, "Users", const MyReadUser()),
                  _drawerItemWidget(Icons.notification_add, "Notifications", const AdminNotificationsPage()),

                ],
              ),
            ),

            // Logout
            Container(
              padding: const EdgeInsets.all(20),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.redAccent.withOpacity(0.1),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text("Logout",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer item helper
  Widget _drawerItemWidget(IconData icon, String title, Widget page) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
