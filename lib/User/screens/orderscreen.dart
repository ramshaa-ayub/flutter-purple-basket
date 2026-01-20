import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Orders",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      backgroundColor: Colors.grey.shade100,
      body: user == null
          ? const Center(child: Text("User not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Orders')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No orders found",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  );
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final orderDoc = orders[i];
                    final order = orderDoc.data() as Map<String, dynamic>;

                    return InkWell(
                      onTap: () {
                        // Navigate to detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserOrderDetailScreen(orderId: orderDoc.id),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🔹 HEADER
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      color: statusColor(
                                              order['status'] ?? 'Pending')
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order['status'] ?? 'Pending',
                                      style: TextStyle(
                                        color: statusColor(
                                            order['status'] ?? 'Pending'),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              /// 👤 USER INFO
                              Text("Name: ${order['name'] ?? ''}"),
                              Text("Phone: ${order['phone'] ?? ''}"),
                              Text("Address: ${order['address'] ?? ''}"),

                              const Divider(height: 24),

                              /// 💰 TOTAL
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    "Rs. ${order['totalAmount'] ?? 0}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
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
    );
  }
}

/// --------------------
/// User Order Detail Screen
/// --------------------
class UserOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const UserOrderDetailScreen({super.key, required this.orderId});

  @override
  State<UserOrderDetailScreen> createState() => _UserOrderDetailScreenState();
}

class _UserOrderDetailScreenState extends State<UserOrderDetailScreen> {
  Map<String, dynamic>? orderData;
  List<Map<String, dynamic>> orderItems = [];
  final CollectionReference ordersRef =
      FirebaseFirestore.instance.collection('Orders');

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Fetch order
      var orderSnap = await ordersRef.doc(widget.orderId).get();
      if (orderSnap.exists) {
        final data = orderSnap.data() as Map<String, dynamic>;
        if (data['userId'] != currentUser.uid) return;

        orderData = data;

        // Fetch order items
        var itemsSnap = await ordersRef
            .doc(widget.orderId)
            .collection('OrderDetails')
            .get();
        orderItems = itemsSnap
            .docs
            // ignore: unnecessary_cast
            .map((e) => e.data() as Map<String, dynamic>)
            .toList();

        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading user order: $e");
    }
  }

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

  void _printInvoice() {
    if (orderData == null) return;

    Printing.layoutPdf(onLayout: (format) async {
      final pdf = pw.Document();

      pdf.addPage(pw.Page(build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Invoice",
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Order ID: ${widget.orderId.substring(0, 6)}"),
            pw.Text("Customer: ${orderData!['name'] ?? 'N/A'}"),
            pw.Text("Phone: ${orderData!['phone'] ?? 'N/A'}"),
            pw.Text("Address: ${orderData!['address'] ?? 'N/A'}"),
            pw.SizedBox(height: 20),
            pw.Text("Products:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Product', 'Qty', 'Price', 'Subtotal'],
              data: orderItems.map((item) {
                final name = item['name'] ?? 'N/A';
                final qty = item['quantity'] ?? 0;
                final price = (item['price'] ?? 0).toDouble();
                final subtotal = (price * qty).toStringAsFixed(2);
                return [name, qty.toString(), price.toStringAsFixed(2), subtotal];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Total: Rs.${(orderData!['totalAmount'] ?? 0).toDouble().toStringAsFixed(2)}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        );
      }));

      return pdf.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (orderData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Order Detail"),
          backgroundColor: Colors.purple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Detail"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
            tooltip: "Print Invoice",
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order #${widget.orderId.substring(0, 6)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor(orderData!['status'] ?? 'pending')
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            orderData!['status'] ?? 'Pending',
                            style: TextStyle(
                              color:
                                  statusColor(orderData!['status'] ?? 'pending'),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Customer: ${orderData!['name'] ?? 'N/A'}"),
                    Text("Phone: ${orderData!['phone'] ?? 'N/A'}"),
                    Text("Address: ${orderData!['address'] ?? 'N/A'}"),
                    const SizedBox(height: 8),
                    Text(
                      "Total: Rs.${(orderData!['totalAmount'] ?? 0).toDouble().toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Products",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // Order Items
            Expanded(
              child: ListView.separated(
                itemCount: orderItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = orderItems[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: item['image'] != null && item['image'] != ""
                          ? Image.memory(base64Decode(item['image']),
                              width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 40),
                      title: Text(item['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text("Rs.${item['price']} x ${item['quantity']}"),
                      trailing: Text(
                        "Rs.${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
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
