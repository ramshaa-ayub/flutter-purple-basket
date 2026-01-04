import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';

class MyReadUser extends StatefulWidget {
  const MyReadUser({super.key});

  @override
  State<MyReadUser> createState() => _MyReadUserState();
}

class _MyReadUserState extends State<MyReadUser> {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('User');

  String _searchQuery = "";

  Uint8List? _getImageBytes(String imageString) {
    try {
      if (imageString.isEmpty) return null;
      return base64Decode(imageString);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmDelete(String docId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await usersCollection.doc(docId).delete();
              if (mounted) {
                ScaffoldMessenger.of(
                  // ignore: use_build_context_synchronously
                  context,
                ).showSnackBar(const SnackBar(content: Text("User Deleted")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Manage Users",
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- Search bar ---
              TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: "Search users by name, email or role...",
                  prefixIcon: const Icon(Icons.search, color: Colors.purple),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- User list ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: usersCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var users = snapshot.data!.docs;

                    var filteredUsers = users.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      var name = (data['User Name'] ?? "")
                          .toString()
                          .toLowerCase();
                      var email = (data['User Email'] ?? "")
                          .toString()
                          .toLowerCase();
                      var role = (data['Role'] ?? "").toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          email.contains(_searchQuery) ||
                          role.contains(_searchQuery);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return const Center(child: Text("No users found"));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final userDoc = filteredUsers[index];
                        final user = userDoc.data() as Map<String, dynamic>;
                        Uint8List? imageBytes = _getImageBytes(
                          user['User Image'] ?? '',
                        );
                        String role = (user['Role'] ?? "User").toString();

                        Color roleColor = role.toLowerCase() == "admin"
                            ? Colors.purple
                            : Colors.grey;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.purple.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border(
                              left: BorderSide(color: Colors.purple, width: 5),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                backgroundImage: imageBytes != null
                                    ? MemoryImage(imageBytes)
                                    : null,
                                child: imageBytes == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.purple,
                                        size: 30,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['User Name'] ?? "No Name",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user['User Email'] ?? "No Email",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_android,
                                          size: 14,
                                          color: Colors.purple[300],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user['User Contact'] ?? "N/A",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 15),
                                        Icon(
                                          Icons.wc,
                                          size: 14,
                                          color: Colors.purple[300],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user['User Gender'] ?? "N/A",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // --- Role ---
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: roleColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          color: roleColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red[300],
                                ),
                                onPressed: () => _confirmDelete(userDoc.id),
                              ),
                            ],
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
      ),
    );
  }
}
