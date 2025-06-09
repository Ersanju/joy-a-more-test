import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  String _formatImageUrl(String url) {
    final regex = RegExp(r'd/([^/]+)');
    final match = regex.firstMatch(url);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? 'Unnamed';
    final desc = product['description'] ?? '';
    final categoryId = product['categoryId'] ?? '';
    final imageUrls = List<String>.from(product['imageUrls'] ?? []);
    final extra = product['extraAttributes'] ?? {};
    final defaultVariant = extra['defaultVariant'] ?? {};
    final otherVariants = List<Map<String, dynamic>>.from(extra['variants'] ?? []);
    final shapes = List<Map<String, dynamic>>.from(extra['shapes'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView(
                children: imageUrls.map((url) {
                  final imageUrl = _formatImageUrl(url);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Center(child: Icon(Icons.image_not_supported, size: 100)),

          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text('Category: $categoryId', style: const TextStyle(fontStyle: FontStyle.italic)),

          const Divider(height: 32),

          if (defaultVariant.isNotEmpty) ...[
            const Text('Default Variant:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Weight: ${defaultVariant['weight']}'),
            Text('Price: ₹${defaultVariant['price']}'),
            Text('Tier: ${defaultVariant['tier']}'),
            Text('SKU: ${defaultVariant['sku']}'),
          ],

          if (otherVariants.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Other Variants:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ...otherVariants.map((v) => ListTile(
              title: Text('${v['weight']} - ₹${v['price']}'),
              subtitle: Text('Tier: ${v['tier']}, SKU: ${v['sku']}'),
            )),
          ],

          if (shapes.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Available Shapes:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 10,
              children: shapes.map((s) {
                final imgUrl = _formatImageUrl(s['imageUrl']);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imgUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                    Text(s['name'], style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
