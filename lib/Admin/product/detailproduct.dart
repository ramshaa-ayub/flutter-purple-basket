import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final CollectionReference products =
        FirebaseFirestore.instance.collection("Products");

    return AdminLayout(
      title: "Product Details",
      child: StreamBuilder<DocumentSnapshot>(
        stream: products.doc(productId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var productData = snapshot.data!.data() as Map<String, dynamic>?;

          if (productData == null) {
            return const Center(child: Text("Product not found."));
          }

          Uint8List? imageBytes;
          if (productData['Image'] != null &&
              productData['Image'].toString().isNotEmpty) {
            try {
              imageBytes = base64Decode(productData['Image']);
            } catch (_) {}
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(16),
                      image: imageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(imageBytes),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageBytes == null
                        ? const Center(
                            child: Icon(Icons.shopping_bag_rounded,
                                size: 80, color: Colors.purple),
                          )
                        : null,
                  ),
                  const SizedBox(height: 25),

                  // Name
                  const Text(
                    "Name",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    productData['Product Name'] ?? "Unnamed Product",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Category
                  const Text(
                    "Category",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    productData['Category'] ?? "Uncategorized",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  // Price
                  const Text(
                    "Price",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "\$${(productData['Price'] != null ? (productData['Price'] as num).toStringAsFixed(2) : '0.00')}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    "Description",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    productData['Description'] ?? "No description provided.",
                    style: const TextStyle(
                        fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),

                  // Created At
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "Created At: ${productData['Created At'] != null ? (productData['Created At'] as Timestamp).toDate().toString() : "Unknown"}",
                        style:
                            TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
