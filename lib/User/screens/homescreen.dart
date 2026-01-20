import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_purple_basket/User/screens/productdetail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = "";
  String _selectedCategory = "";

  Uint8List? userImg;
  String firstName = "";

  final categoryRef = FirebaseFirestore.instance.collection("Category");
  final productRef = FirebaseFirestore.instance.collection("Products");

  final wishlistRef = FirebaseFirestore.instance.collection("Wishlist");

  Map<String, bool> wishlistMap = {}; // productId -> isInWishlist

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadWishlist();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("User")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final name = data['User Name'] ?? "";
      setState(() {
        firstName = name.toString().split(" ").first;
        if ((data['User Image'] ?? "").toString().isNotEmpty) {
          userImg = base64Decode(data['User Image']);
        }
      });
    }
  }

  Future<void> _loadWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await wishlistRef.doc(user.uid).collection("items").get();

    setState(() {
      wishlistMap = {
        for (var doc in snapshot.docs) doc.id: true,
      };
    });
  }

  Uint8List? _img(String base64) {
    try {
      return base64.isEmpty ? null : base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  /// ✅ ADD TO CART LOGIC
  Future<void> _addToCart({
    required String productId,
    required String name,
    required int price,
    required String image,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartItemRef = FirebaseFirestore.instance
        .collection("Cart")
        .doc(user.uid)
        .collection("items")
        .doc(productId);

    final snap = await cartItemRef.get();

    if (snap.exists) {
      await cartItemRef.update({
        "quantity": FieldValue.increment(1),
      });
    } else {
      await cartItemRef.set({
        "name": name,
        "price": price,
        "image": image,
        "quantity": 1,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Added to cart",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// ✅ WISHLIST LOGIC
  Future<void> _toggleWishlist(String productId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = wishlistRef.doc(user.uid).collection("items").doc(productId);

    if (wishlistMap[productId] == true) {
      await docRef.delete();
      setState(() => wishlistMap[productId] = false);
    } else {
      await docRef.set({
        "name": data['Product Name'],
        "price": data['Price'],
        "image": data['Image'],
        "createdAt": FieldValue.serverTimestamp(),
      });
      setState(() => wishlistMap[productId] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// 🔮 HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade800,
                  Colors.purple.shade500,
                  Colors.purple.shade300,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Purple Basket",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Best Online Store",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              userImg != null ? MemoryImage(userImg!) : null,
                          child: userImg == null
                              ? const Icon(Icons.person,
                                  color: Colors.deepPurple)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Hello $firstName",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// 🔍 SEARCH
                TextField(
                  onChanged: (v) {
                    setState(() {
                      _search = v.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search products",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🖼️ BANNER
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _search = "";
                        _selectedCategory = "";
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        "assets/images/banner6.jpg",
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 📂 CATEGORIES
                  const Text(
                    "Categories",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 100,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: categoryRef.orderBy("name").snapshots(),
                      builder: (_, s) {
                        if (!s.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: s.data!.docs.length,
                          itemBuilder: (_, i) {
                            final data =
                                s.data!.docs[i].data() as Map<String, dynamic>;
                            final img = _img(data['image'] ?? '');
                            final isSelected =
                                _selectedCategory == data['name'];

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory =
                                      isSelected ? "" : data['name'];
                                });
                              },
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purple.shade500
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12, blurRadius: 5)
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          Colors.purple.shade50,
                                      backgroundImage: img != null
                                          ? MemoryImage(img)
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      data['name'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🛍️ PRODUCTS
                  const Text(
                    "Products",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: productRef
                        .orderBy("Created At", descending: true)
                        .snapshots(),
                    builder: (_, s) {
                      if (!s.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final products = s.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['Product Name']
                            .toString()
                            .toLowerCase();

                        if (_search.isNotEmpty) {
                          return name.contains(_search);
                        }

                        if (_selectedCategory.isNotEmpty) {
                          return data['Category'] == _selectedCategory;
                        }

                        return true;
                      }).toList();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (_, i) {
                          final doc = products[i];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final img = _img(data['Image'] ?? '');
                          final isInWishlist =
                              wishlistMap[doc.id] ?? false;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailProductScreen(productId: doc.id),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 5)
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: img != null
                                              ? Image.memory(
                                                  img,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                )
                                              : Container(
                                                  color: Colors.grey.shade300),
                                        ),
                                        // Wishlist heart
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              _toggleWishlist(doc.id, data);
                                            },
                                            child: Icon(
                                              isInWishlist
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Colors.red,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      data['Product Name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      "Rs. ${data['Price']}",
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _addToCart(
                                            productId: doc.id,
                                            name: data['Product Name'],
                                            price: int.parse(
                                                data['Price'].toString()),
                                            image: data['Image'],
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                        ),
                                        child: const Text(
                                          "Add to Cart",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
