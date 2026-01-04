import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_purple_basket/Admin/layout.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const EditProductScreen(this.product, {super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;

  final CollectionReference products = FirebaseFirestore.instance.collection("Products");
  final CollectionReference categories = FirebaseFirestore.instance.collection("Category");

  String? selectedCategory;
  Uint8List? _imageBytes;
  String imageURL = '';
  bool _isLoading = false;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['Product Name'] ?? '');
    priceController = TextEditingController(text: widget.product['Price']?.toString() ?? '');
    descController = TextEditingController(text: widget.product['Description'] ?? '');
    selectedCategory = widget.product['Category'];

    if (widget.product['Image'] != null && widget.product['Image'].toString().isNotEmpty) {
      _imageBytes = base64Decode(widget.product['Image']);
      imageURL = widget.product['Image'];
    }
  }

  Future<void> pickImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        imageURL = base64Encode(bytes);
      });
    }
  }

  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await products.doc(widget.product['id']).update({
      "Product Name": nameController.text.trim(),
      "Category": selectedCategory,
      "Price": double.tryParse(priceController.text) ?? 0,
      "Description": descController.text.trim(),
      "Image": imageURL,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product updated successfully")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Edit Product",
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
                  // Product Image Picker
                  GestureDetector(
                    onTap: pickImage,
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

                  // Product Name
                  TextFormField(
                    controller: nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? "Product name required" : null,
                    decoration: InputDecoration(
                      labelText: "Product Name",
                      prefixIcon: Icon(Icons.label_outline, color: Colors.purple.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: categories.orderBy("name").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      var cats = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: cats.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: data['name'],
                            child: Text(data['name']),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedCategory = val),
                        decoration: InputDecoration(
                          labelText: "Category",
                          prefixIcon: Icon(Icons.category, color: Colors.purple.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? "Select category" : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Price
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty ? "Price required" : null,
                    decoration: InputDecoration(
                      labelText: "Price",
                      prefixIcon: Icon(Icons.attach_money, color: Colors.purple.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
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

                  // Action Buttons
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
                          onPressed: _isLoading ? null : updateProduct,
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
                                  "Update Product",
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
