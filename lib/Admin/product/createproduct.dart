import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';
import 'package:image_picker/image_picker.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final CollectionReference products = FirebaseFirestore.instance.collection("Products");

  String? selectedCategory;
  Uint8List? _imageBytes;
  String imageBase64 = '';
  bool _isLoading = false;

  final ImagePicker pickImg = ImagePicker();

  Future<void> pickImage() async {
    final XFile? img = await pickImg.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> createProduct() async {
    if (!_formKey.currentState!.validate() || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select a category")),
      );
      return;
    }
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product image")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await products.add({
        "Product Name": nameController.text.trim(),
        "Category": selectedCategory,
        "Price": double.tryParse(priceController.text) ?? 0,
        "Description": descController.text.trim(),
        "Image": imageBase64,
        "Created At": Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Add New Product",
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 480,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(32),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Center(
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
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: nameController,
                    validator: (val) => val!.trim().isEmpty ? "Product name is required" : null,
                    decoration: InputDecoration(
                      labelText: "Product Name",
                      prefixIcon: Icon(Icons.label_outline, color: Colors.purple.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("Category").orderBy("name").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      var categories = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categories.map((cat) {
                          var data = cat.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: data["name"],
                            child: Text(data["name"]),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedCategory = val),
                        decoration: InputDecoration(
                          labelText: "Select Category",
                          prefixIcon: Icon(Icons.category, color: Colors.purple.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (val) => val == null ? "Please select a category" : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.trim().isEmpty ? "Price is required" : null,
                    decoration: InputDecoration(
                      labelText: "Price",
                      prefixIcon: Icon(Icons.attach_money, color: Colors.purple.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Description",
                      prefixIcon: Icon(Icons.description, color: Colors.purple.shade600),
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
                          onPressed: _isLoading ? null : createProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Save Product", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
