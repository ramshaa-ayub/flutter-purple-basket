import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';
import 'package:flutter_purple_basket/Admin/order/detailorder.dart';


class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _searchQuery = "";

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ready':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    await FirebaseFirestore.instance
        .collection('Orders')
        .doc(orderId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Orders",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🔍 SEARCH BAR
            TextField(
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search by name, phone or order id...",
                prefixIcon: Icon(Icons.search, color: Colors.purple.shade600),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📦 ORDERS LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Orders')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allOrders = snapshot.data!.docs;

                  final orders = allOrders.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final orderId = doc.id.substring(0, 6).toLowerCase();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final phone = (data['phone'] ?? '').toString().toLowerCase();

                    return orderId.contains(_searchQuery) ||
                        name.contains(_searchQuery) ||
                        phone.contains(_searchQuery);
                  }).toList();

                  if (orders.isEmpty) {
                    return const Center(child: Text("No orders found"));
                  }

                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final orderDoc = orders[i];
                      final order = orderDoc.data() as Map<String, dynamic>;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Navigate to DetailOrderScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailOrderScreen(orderId: orderDoc.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// HEADER
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Order #${orderDoc.id.substring(0, 6)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor(order['status'])
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        order['status'],
                                        style: TextStyle(
                                          color: statusColor(order['status']),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                /// USER INFO
                                Text("Name: ${order['name']}"),
                                Text("Phone: ${order['phone']}"),
                                Text("Address: ${order['address']}"),

                                const Divider(height: 24),

                                /// ITEMS
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('Orders')
                                      .doc(orderDoc.id)
                                      .collection('OrderDetails')
                                      .snapshots(),
                                  builder: (context, itemSnap) {
                                    if (!itemSnap.hasData) {
                                      return const SizedBox();
                                    }

                                    return Column(
                                      children: itemSnap.data!.docs.map((itemDoc) {
                                        final item = itemDoc.data() as Map<String, dynamic>;

                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: item['image'] != null && item['image'] != ""
                                              ? Image.memory(
                                                  base64Decode(item['image']),
                                                  width: 45,
                                                )
                                              : const Icon(Icons.image),
                                          title: Text(item['name']),
                                          subtitle: Text(
                                              "Rs. ${item['price']} x ${item['quantity']}"),
                                          trailing: Text(
                                            "Rs. ${item['price'] * item['quantity']}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),

                                const Divider(),

                                /// TOTAL + ACTIONS
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total: Rs. ${order['totalAmount']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              updateStatus(orderDoc.id, "Ready"),
                                          child: const Text("Mark Ready"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              updateStatus(orderDoc.id, "Delivered"),
                                          child: const Text("Delivered"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}      