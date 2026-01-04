import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';
import 'package:flutter_purple_basket/Admin/product/createproduct.dart';
import 'package:flutter_purple_basket/Admin/product/detailproduct.dart';
import 'package:flutter_purple_basket/Admin/product/editproduct.dart';

class ReadProductScreen extends StatefulWidget {
  const ReadProductScreen({super.key});

  @override
  State<ReadProductScreen> createState() => _ReadProductScreenState();
}

class _ReadProductScreenState extends State<ReadProductScreen> {
  final CollectionReference productRef = FirebaseFirestore.instance.collection("Products");
  String _searchQuery = "";

  Uint8List? _getImageBytes(String imageStr) {
    try {
      if (imageStr.isEmpty) return null;
      return base64Decode(imageStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmDelete(String docId) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Product"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await productRef.doc(docId).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product deleted")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Products",
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// 🔍 Search
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    prefixIcon: Icon(Icons.search, color: Colors.purple.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.purple.shade100),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// 📦 Product List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: productRef.orderBy("Created At", descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final filtered = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['Product Name'] ?? '').toString().toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) return const Center(child: Text("No products found"));

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final imageBytes = _getImageBytes(data['Image'] ?? '');

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border(left: BorderSide(color: Colors.purple.shade600, width: 5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.purple.shade50,
                                backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                                child: imageBytes == null
                                    ? Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.purple.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                data['Product Name'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Category: ${data['Category']} | Price: ${data['Price']}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: "View Details",
                                    icon: Icon(Icons.visibility, color: Colors.purple.shade600),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(productId: doc.id),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: "Edit",
                                    icon: Icon(Icons.edit, color: Colors.purple.shade600),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProductScreen({'id': doc.id, ...data}),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _confirmDelete(doc.id),
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
              ],
            ),
          ),

          /// ➕ FAB
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.purple.shade700,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Product",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateProductScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
