import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:joy_a_more_test/product_model.dart';
import 'package:uuid/uuid.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _productDescController = TextEditingController();
  final _careInstrucController = TextEditingController();
  final _deliveryInfoController = TextEditingController();
  final _categoryIdController = TextEditingController();
  final _imageUrlsController = TextEditingController();
  final _stockQtyController = TextEditingController();
  final _tagsController = TextEditingController();

  final List<Variant> _variants = [];
  final List<Shape> _shapes = [];
  Variant? _defaultVariant;

  bool _isSubmitting = false;

  /// --------- UTIL METHODS ---------

  /// Converts a Google Drive share URL to a direct image UR
  String convertGoogleDriveUrl(String url) {
    final regex = RegExp(r'd/([^/]+)');
    final match = regex.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url; // Return as-is if not a Drive link
  }

  /// Checks if the given URL is a valid HTTP/HTTPS link
  bool _isValidUrl(String url) {
    final pattern = r'^(http|https):\/\/[^ "]+$';
    return RegExp(pattern).hasMatch(url);
  }

  Future<bool> _isProductNameDuplicate(String name) async {
    final query =
        await FirebaseFirestore.instance
            .collection('products')
            .where('name', isEqualTo: name)
            .limit(1)
            .get();
    return query.docs.isNotEmpty;
  }

  /// --------- DIALOGS ---------
  void _showAddVariantDialog() {
    final weightController = TextEditingController();
    final tierController = TextEditingController();
    final priceController = TextEditingController();
    final oldPriceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Add Variant'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Weight'),
                  ),
                  TextField(
                    controller: tierController,
                    decoration: const InputDecoration(labelText: 'Tier'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: oldPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Old Price (Optional)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final weight = weightController.text.trim();
                  final tier = int.tryParse(tierController.text.trim()) ?? 1;
                  final price =
                      double.tryParse(priceController.text.trim()) ?? 0;
                  final oldPrice = double.tryParse(
                    oldPriceController.text.trim(),
                  );

                  if (weight.isEmpty || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid weight or price')),
                    );
                    return;
                  }

                  final sku =
                      "cake_${weight}_${tier}_${price.toStringAsFixed(0)}"
                          .replaceAll(' ', '')
                          .toLowerCase();

                  if (_variants.any((v) => v.sku == sku)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Duplicate SKU')),
                    );
                    return;
                  }

                  final discount =
                      (oldPrice != null && oldPrice > price)
                          ? ((oldPrice - price) / oldPrice * 100)
                          : null;

                  final variant = Variant(
                    weight: weight,
                    tier: tier,
                    price: price,
                    oldPrice: oldPrice,
                    discount: discount,
                    sku: sku,
                  );

                  setState(() => _variants.add(variant));
                  Navigator.pop(context);
                },
                child: const Text('Add Variant'),
              ),
            ],
          ),
    );
  }

  void _showAddShapeDialog() {
    final nameController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Add Shape'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final url = imageUrlController.text.trim();

                  if (name.isEmpty || !_isValidUrl(url)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid shape or URL')),
                    );
                    return;
                  }

                  setState(() => _shapes.add(Shape(name: name, imageUrl: url)));
                  Navigator.pop(context);
                },
                child: const Text('Add Shape'),
              ),
            ],
          ),
    );
  }

  /// --------- SUBMIT ---------
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required details.')),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one variant.')),
      );
      return;
    }

    if (_defaultVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a default variant.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    if (await _isProductNameDuplicate(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product with this name already exists.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final productId = _uuid.v4();
    final product = CakeProduct(
      id: productId,
      name: name,
      productDescription:
          _productDescController.text
              .trim()
              .split('\n')
              .where((e) => e.trim().isNotEmpty)
              .toList(),

      careInstruction:
          _careInstrucController.text
              .trim()
              .split('\n')
              .where((e) => e.trim().isNotEmpty)
              .toList(),

      deliveryInformation:
          _deliveryInfoController.text
              .trim()
              .split('\n')
              .where((e) => e.trim().isNotEmpty)
              .toList(),
      categoryId: _categoryIdController.text.trim(),
      imageUrls:
          _imageUrlsController.text
              .trim()
              .split(',')
              .map((e) => e.trim())
              .where(_isValidUrl)
              .map((url) => convertGoogleDriveUrl(url))
              .toList(),
      isAvailable: true,
      stockQuantity: int.tryParse(_stockQtyController.text.trim()) ?? 0,
      createdAt: DateTime.now(),
      tags:
          _tagsController.text.trim().split(',').map((e) => e.trim()).toList(),
      popularityScore: 0,
      reviews: [],
      extraAttributes: ExtraAttributes(
        defaultVariant: _defaultVariant!,
        variants: _variants,
        shapes: _shapes,
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .set(product.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  /// --------- UI ---------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body:
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ), // initial state
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          if (val.trim().length < 3) {
                            return 'Minimum 3 characters required';
                          }
                          if (val.length > 100) return 'Too long';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _productDescController,
                        minLines: 4,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Product Description',
                          hintText: 'Enter bullet points...',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final lines =
                              val
                                  .trim()
                                  .split('\n')
                                  .where((line) => line.trim().isNotEmpty)
                                  .toList();
                          if (lines.length < 2) {
                            return 'Enter at least 2 bullet points';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _careInstrucController,
                        minLines: 4,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Care Instructions',
                          hintText: 'Enter bullet points...',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final lines =
                              val
                                  .trim()
                                  .split('\n')
                                  .where((line) => line.trim().isNotEmpty)
                                  .toList();
                          if (lines.length < 2) {
                            return 'Enter at least 2 bullet points';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _deliveryInfoController,
                        minLines: 4,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Information',
                          hintText: 'Enter bullet points...',
                          labelStyle: TextStyle(fontWeight: FontWeight.normal),
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final lines =
                              val
                                  .trim()
                                  .split('\n')
                                  .where((line) => line.trim().isNotEmpty)
                                  .toList();
                          if (lines.length < 2) {
                            return 'Enter at least 2 bullet points';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryIdController,
                        decoration: const InputDecoration(
                          labelText: 'Category ID',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ), // initial state
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageUrlsController,
                        decoration: const InputDecoration(
                          labelText: 'Image URLs (comma-separated)',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ), // initial state
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final urls =
                              val?.split(',').map((e) => e.trim()).toList() ??
                              [];
                          if (urls.isEmpty) {
                            return 'At least one image URL required';
                          }
                          for (var url in urls) {
                            if (!_isValidUrl(url)) return 'Invalid URL: $url';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stockQtyController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ), // initial state
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma-separated)',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ), // initial state
                          floatingLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddVariantDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variant'),
                      ),
                      ..._variants.map(
                        (v) => RadioListTile<Variant>(
                          value: v,
                          groupValue: _defaultVariant,
                          onChanged:
                              (val) => setState(() => _defaultVariant = val),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weight: ${v.weight}'),
                              Text('Price: ₹${v.price}'),
                              Text('Tier: ${v.tier}'),
                            ],
                          ),
                          subtitle: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('SKU: ${v.sku}'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton.icon(
                        onPressed: _showAddShapeDialog,
                        icon: const Icon(Icons.shape_line),
                        label: const Text('Add Shape'),
                      ),
                      ..._shapes.map(
                        (s) => ListTile(
                          title: Text(s.name),
                          subtitle: Text(s.imageUrl),
                          leading: const Icon(Icons.check),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _submitProduct,
                        child: const Text('Add Product'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
