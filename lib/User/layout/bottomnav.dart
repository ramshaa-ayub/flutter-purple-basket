import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_purple_basket/User/screens/cartscreen.dart';
import 'package:flutter_purple_basket/User/screens/homescreen.dart';
import 'package:flutter_purple_basket/User/screens/orderscreen.dart';
import 'package:flutter_purple_basket/User/screens/profilescreen.dart';
import 'package:flutter_purple_basket/User/screens/wishlistscreen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    WishlistScreen(),
    CartScreen(),
    OrdersScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      /// ❤️ WISHLIST + 🛒 CART COUNT
      bottomNavigationBar: user == null
          ? _buildBottomBar(0, 0)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Cart")
                  .doc(user.uid)
                  .collection("items")
                  .snapshots(),
              builder: (context, cartSnap) {
                final cartCount =
                    cartSnap.hasData ? cartSnap.data!.docs.length : 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("Wishlist")
                      .doc(user.uid)
                      .collection("items")
                      .snapshots(),
                  builder: (context, wishSnap) {
                    final wishlistCount =
                        wishSnap.hasData ? wishSnap.data!.docs.length : 0;

                    return _buildBottomBar(cartCount, wishlistCount);
                  },
                );
              },
            ),
    );
  }

  BottomNavigationBar _buildBottomBar(int cartCount, int wishlistCount) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color.fromRGBO(103, 58, 183, 1),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),

        /// ❤️ WISHLIST BADGE
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: Icons.favorite_border,
            count: wishlistCount,
          ),
          label: 'Wishlist',
        ),

        /// 🛒 CART BADGE
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: Icons.shopping_cart_outlined,
            count: cartCount,
          ),
          label: 'Cart',
        ),

        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Orders',
        ),

        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    required int count,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: _Badge(count: count),
          ),
      ],
    );
  }
}

/// 🔴 BADGE (USED FOR CART & WISHLIST)
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
