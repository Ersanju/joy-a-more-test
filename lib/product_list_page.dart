import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:joy_a_more_test/product_detail_page.dart';
import 'package:joy_a_more_test/product_model.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Products"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading products"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No products found."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              if (data is! Map<String, dynamic>) return const SizedBox.shrink();

              final name = data['name'] ?? 'Unnamed Product';
              final categoryId = data['categoryId'] ?? 'No category';
              final imageUrls = List<String>.from(data['imageUrls'] ?? []);
              final defaultPrice = data['extraAttributes']?['defaultVariant']?['price'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: InkWell(
                    onTap: () {
                      final product = Product.fromJson({...data, 'id': docs[index].id});
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(product: product.toJson()), // <-- convert to map
                        ),
                      );
                    },
                    child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrls.isNotEmpty
                              ? Image.network(imageUrls[0],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 36),
                            ),
                          )
                              : Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 36),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Category: $categoryId',
                                  style: const TextStyle(fontSize: 13)),
                              if (defaultPrice != null)
                                Text(
                                  'Price: ₹$defaultPrice',
                                  style: const TextStyle(
                                      color: Colors.green, fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
