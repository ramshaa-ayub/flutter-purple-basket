import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';

class DetailOrderScreen extends StatefulWidget {
  final String orderId;

  const DetailOrderScreen({super.key, required this.orderId});

  @override
  State<DetailOrderScreen> createState() => _DetailOrderScreenState();
}

class _DetailOrderScreenState extends State<DetailOrderScreen> {
  final CollectionReference ordersRef = FirebaseFirestore.instance.collection('Orders');
  final CollectionReference orderDetailsRef = FirebaseFirestore.instance.collection('OrderDetails');

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Order Details",
      child: FutureBuilder<DocumentSnapshot>(
        future: ordersRef.doc(widget.orderId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var order = snapshot.data!.data() as Map<String, dynamic>;
          String userName = order['Customer Name'] ?? "N/A";
          String phone = order['Contact Phone'] ?? "N/A";
          String address = order['DeliveryAddress'] ?? "N/A";
          String status = order['Status'] ?? "Pending";
          double total = (order['TotalAmount'] ?? 0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Info
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order ID: ${widget.orderId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Customer: $userName"),
                      Text("Phone: $phone"),
                      Text("Address: $address"),
                      const SizedBox(height: 8),
                      Text("Status: $status"),
                      Text("Total: \$${total.toStringAsFixed(2)}"),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("Products", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 10),

              // Order Items
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: orderDetailsRef.where('OrderId', isEqualTo: widget.orderId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var items = snapshot.data!.docs;

                    if (items.isEmpty) return const Center(child: Text("No items found"));

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var item = items[index].data() as Map<String, dynamic>;
                        String name = item['Product Name'] ?? "N/A";
                        double price = (item['Price'] ?? 0).toDouble();
                        int qty = (item['Quantity'] ?? 0).toInt();

                        return ListTile(
                          tileColor: Colors.purple.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Qty: $qty x \$${price.toStringAsFixed(2)}"),
                          trailing: Text("\$${(price * qty).toStringAsFixed(2)}"),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
