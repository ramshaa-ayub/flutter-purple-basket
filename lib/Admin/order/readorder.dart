import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';
import 'package:flutter_purple_basket/Admin/order/detailorder.dart';


class MyReadOrder extends StatefulWidget {
  const MyReadOrder({super.key});

  @override
  State<MyReadOrder> createState() => _MyReadOrderState();
}

class _MyReadOrderState extends State<MyReadOrder> {
  final CollectionReference ordersRef = FirebaseFirestore.instance.collection('Orders');

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Manage Orders",
      child: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.orderBy('Order Date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var orders = snapshot.data!.docs;

          if (orders.isEmpty) return const Center(child: Text("No orders found"));

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            separatorBuilder: (_, __) => const SizedBox(height: 15),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index].data() as Map<String, dynamic>;
              String orderId = orders[index].id;
              String userName = order['Customer Name'] ?? "N/A";
              String phone = order['Contact Phone'] ?? "N/A";
              String status = order['Status'] ?? "Pending";
              double total = (order['TotalAmount'] ?? 0).toDouble();

              Color statusColor = status == "Delivered"
                  ? Colors.green
                  : status == "Pending"
                      ? Colors.orange
                      : Colors.blue;

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailOrderScreen(orderId: orderId)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border(left: BorderSide(color: Colors.purple, width: 5)),
                    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order ID: $orderId",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("Customer: $userName"),
                          Text("Phone: $phone"),
                          const SizedBox(height: 4),
                          Text("Total: \$${total.toStringAsFixed(2)}"),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
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
    );
  }
}
