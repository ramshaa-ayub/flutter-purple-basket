import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_purple_basket/Admin/category/readcat.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';
import 'package:flutter_purple_basket/Admin/notification/admin_notification_page.dart';
import 'package:flutter_purple_basket/Admin/notification/admin_notification_service.dart';
import 'package:flutter_purple_basket/Admin/order/readorder.dart';
import 'package:flutter_purple_basket/Admin/product/readproduct.dart';
import 'package:flutter_purple_basket/Admin/user/readuser.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int newOrderCount = 0;

  @override
  void initState() {
    super.initState();

    /// 🔴 Badge count from service (NO FCM)
    AdminNotificationService.unreadCount().listen((count) {
      setState(() {
        newOrderCount = count;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference categoryRef =
        FirebaseFirestore.instance.collection("Category");
    final CollectionReference productRef =
        FirebaseFirestore.instance.collection("Products");
    final CollectionReference orderRef =
        FirebaseFirestore.instance.collection("Orders");
    final CollectionReference userRef =
        FirebaseFirestore.instance.collection("User");

    return AdminLayout(
      title: "Dashboard",
      appBarActions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminNotificationsPage(),
                  ),
                );
              },
            ),
            if (newOrderCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$newOrderCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🎀 Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade800,
                    Colors.purple.shade500,
                    Colors.purple.shade300,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back, Admin!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Overview of your e-commerce store.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Statistics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            /// 📊 Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: [
                _buildStatStream(
                  categoryRef,
                  "Categories",
                  Icons.category_outlined,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ReadCategoryScreen()),
                  ),
                ),
                _buildStatStream(
                  productRef,
                  "Products",
                  Icons.shopping_bag_outlined,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReadProductScreen()),
                  ),
                ),
                _buildStatStream(
                  orderRef,
                  "Orders",
                  Icons.shopping_cart_outlined,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminOrdersScreen()),
                  ),
                ),
                _buildStatStream(
                  userRef,
                  "Users",
                  Icons.group_outlined,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReadUser()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatStream(
    CollectionReference ref,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final count =
            snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
        return _StatCard(
          title: title,
          count: count,
          icon: icon,
          color: color,
          onTap: onTap,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
