import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';
import 'package:flutter_purple_basket/Admin/category/readcat.dart';


class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final CollectionReference categoryRef = FirebaseFirestore.instance.collection("Category");
  final ImagePicker pickImg = ImagePicker();

  String imageURL = '';          // Base64 string
  Uint8List? _imageBytes;        // For preview
  bool _isLoading = false;

  // --- Pick image & convert to Base64 ---
  Future<void> getImage() async {
    final XFile? img = await pickImg.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final Uint8List getBytes = await img.readAsBytes();
      setState(() {
        _imageBytes = getBytes;
        imageURL = base64Encode(getBytes);
      });
    }
  }

  // --- Create category ---
  Future<void> createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    if (imageURL.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check duplicate
      final query = await categoryRef.where('name', isEqualTo: nameController.text.trim()).get();
      if (query.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category already exists"), backgroundColor: Colors.orange),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Save in Firestore
      await categoryRef.add({
        "name": nameController.text.trim(),
        "image": imageURL,       // Base64
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category added successfully"), backgroundColor: Colors.green),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReadCategoryScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Create Category",
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: getImage,
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_imageBytes!, height: 150, width: 150, fit: BoxFit.cover),
                          )
                        : Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add_a_photo, size: 50, color: Colors.purple.shade700),
                          ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    validator: (val) => val!.trim().isEmpty ? "Category name required" : null,
                    decoration: InputDecoration(
                      labelText: "Category Name",
                      prefixIcon: Icon(Icons.label_outline, color: Colors.purple.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.purple.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : createCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  "Save Category",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
