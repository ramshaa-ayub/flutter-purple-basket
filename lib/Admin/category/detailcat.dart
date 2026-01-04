import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';

class DetailCategoryScreen extends StatelessWidget {
  final String categoryId;

  const DetailCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final CollectionReference categoryRef =
        FirebaseFirestore.instance.collection("Category");

    return AdminLayout(
      title: "Category Details",
      child: StreamBuilder<DocumentSnapshot>(
        stream: categoryRef.doc(categoryId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categoryData =
              snapshot.data!.data() as Map<String, dynamic>?;

          if (categoryData == null) {
            return const Center(child: Text("Category not found."));
          }

          Uint8List? imageBytes;
          if (categoryData['image'] != null &&
              categoryData['image'].toString().isNotEmpty) {
            try {
              imageBytes = base64Decode(categoryData['image']);
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
                  // Image
                  Container(
                    width: double.infinity,
                    height: 200,
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
                            child: Icon(Icons.category_rounded,
                                size: 80, color: Colors.purple),
                          )
                        : null,
                  ),
                  const SizedBox(height: 25),

                  // Name
                  const Text(
                    "Category Name",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    categoryData['name'] ?? "Unnamed Category",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Created At
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "Created At: ${categoryData['createdAt'] != null ? (categoryData['createdAt'] as Timestamp).toDate().toString() : "Unknown"}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
