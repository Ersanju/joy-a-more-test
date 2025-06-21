import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    final name = productData['name'] ?? 'Unnamed';
    final imageUrls = List<String>.from(productData['imageUrls'] ?? []);
    final price = productData['extraAttributes']?['defaultVariant']?['price'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (imageUrls.isNotEmpty)
              Image.network(
                imageUrls.first,
                height: 250,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (price != '') Text("Price: ₹$price", style: const TextStyle(fontSize: 20, color: Colors.green)),
                  const SizedBox(height: 16),
                  Text("More product details here..."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
