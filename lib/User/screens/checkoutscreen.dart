import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String phone = '';
  String address = '';
  String notes = '';

  List<Map<String, dynamic>> cartItems = [];
  int subtotal = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartSnap = await FirebaseFirestore.instance
        .collection('Cart')
        .doc(user.uid)
        .collection('items')
        .get();

    int tempSubtotal = 0;
    final items = cartSnap.docs.map((doc) {
      final data = doc.data();
      final int quantity = int.parse(doc['quantity'].toString());
      final int price = int.parse(doc['price'].toString());

      tempSubtotal += (quantity * price);

      return {
        'id': doc.id,
        'name': data['name'],
        'price': price,
        'quantity': quantity,
        'image': data['image'],
      };
    }).toList();

    setState(() {
      cartItems = items;
      subtotal = tempSubtotal;
    });
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState?.validate() != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderRef = FirebaseFirestore.instance.collection('Orders').doc();
    final batch = FirebaseFirestore.instance.batch();

    // 1️⃣ Save order
    batch.set(orderRef, {
      'userId': user.uid,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'status': 'Pending',
      'totalAmount': subtotal,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Save order items
    for (var item in cartItems) {
      final detailRef = orderRef.collection('OrderDetails').doc();
      batch.set(detailRef, {
        'productId': item['id'],
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'image': item['image'],
      });
    }

    // 3️⃣ Create admin notification
    final notifRef =
        FirebaseFirestore.instance.collection('AdminNotifications').doc();
    batch.set(notifRef, {
      'title': "New Order Received",
      'body': "Order #${orderRef.id.substring(0, 6)} placed by $name",
      'orderId': orderRef.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4️⃣ Clear cart
    final cartRef = FirebaseFirestore.instance
        .collection('Cart')
        .doc(user.uid)
        .collection('items');

    final cartSnap = await cartRef.get();
    for (var doc in cartSnap.docs) {
      batch.delete(doc.reference);
    }

    // Commit batch
    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Order placed successfully!🎀",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );

    Navigator.pop(context); // go back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: cartItems.isEmpty
            ? const Center(child: Text("Your cart is empty"))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 📝 FORM
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "Name"),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter name" : null,
                            onChanged: (v) => name = v,
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "Phone"),
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter phone" : null,
                            onChanged: (v) => phone = v,
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "Address"),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter address" : null,
                            onChanged: (v) => address = v,
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "Notes"),
                            onChanged: (v) => notes = v,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// 🛒 CART ITEMS
                    const Text(
                      "Your Cart",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      itemBuilder: (_, i) {
                        final item = cartItems[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: item['image'] != null && item['image'] != ""
                                ? Image.memory(
                                    base64Decode(item['image']),
                                    width: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image),
                            title: Text(item['name']),
                            subtitle:
                                Text("Rs. ${item['price']} x ${item['quantity']}"),
                            trailing: Text(
                                "Rs. ${item['price'] * item['quantity']}"),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    /// 💰 SUBTOTAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Rs. $subtotal",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    /// ✅ PLACE ORDER BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Place Order",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
