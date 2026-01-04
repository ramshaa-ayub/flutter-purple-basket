import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_purple_basket/Admin/category/createcat.dart';
import 'package:flutter_purple_basket/Admin/category/detailcat.dart';
import 'package:flutter_purple_basket/Admin/category/editcat.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';

class ReadCategoryScreen extends StatefulWidget {
  const ReadCategoryScreen({super.key});

  @override
  State<ReadCategoryScreen> createState() => _ReadCategoryScreenState();
}

class _ReadCategoryScreenState extends State<ReadCategoryScreen> {
  final CollectionReference categoryRef =
      FirebaseFirestore.instance.collection("Category");

  String _searchQuery = "";

  Uint8List? _getImageBytes(String imageStr) {
    try {
      if (imageStr.isEmpty) return null;
      return base64Decode(imageStr);
    } catch (e) {
      return null;
    }
  }

  Future<void> _confirmDelete(String docId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Category"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await categoryRef.doc(docId).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Category deleted")),
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
      title: "Categories",
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 🔍 Search Bar
                TextField(
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: "Search categories...",
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

                // 📄 Category List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: categoryRef.orderBy("name").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text("No categories found"));
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;

                          Uint8List? imageBytes = _getImageBytes(data['image'] ?? '');

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border(
                                left: BorderSide(
                                  color: Colors.purple.shade600,
                                  width: 5,
                                ),
                              ),
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
                                data['name'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   IconButton(
                                    tooltip: "View Details",
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.purple,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetailCategoryScreen(
                                            categoryId: doc.id,
                                          ),
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
                                          builder: (_) => EditCategoryScreen({
                                            'id': doc.id,
                                            'name': data['name'],
                                            'image': data['image'] ?? '',
                                          }),
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

          // ➕ Floating Button
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.purple.shade700,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Category",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCategoryScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
