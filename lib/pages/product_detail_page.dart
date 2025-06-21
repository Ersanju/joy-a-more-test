import 'dart:async';

import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedImage = 0;
  late PageController _pageController;
  int selectedVariantIndex = 0;
  Map<String, dynamic>? selectedCardData;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = List<String>.from(widget.productData['imageUrls'] ?? []);
    final name = widget.productData['name'] ?? 'Unnamed';
    final variants = List<Map<String, dynamic>>.from(
      widget.productData['extraAttributes']?['cakeAttribute']?['variants'] ?? [],
    );
    final selectedVariant = variants[selectedVariantIndex];
    final double price = (selectedVariant['price'] as num).toDouble();
    final double? oldPrice =
    selectedVariant['oldPrice'] != null
        ? (selectedVariant['oldPrice'] as num).toDouble()
        : null;


    return Scaffold(
      appBar: AppBar(
        title: Text('Product description'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildImageCarousel(imageUrls),
              const SizedBox(height: 20),
              buildProductPriceRow(
                name: name,
                price: price,
                oldPrice: oldPrice,
              ),

              //  Price inclusive
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  showPriceDetailsBottomSheet(
                    context: context,
                    price: price,
                    oldPrice: oldPrice,
                  );
                },
                child: const Text(
                  "Price inclusive of all taxes >",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),

              // Available options
              const Text(
                "Available Options",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              buildVariantSelector(
                variants: variants,
                selectedIndex: selectedVariantIndex,
                onVariantSelected: (index) {
                  setState(() {
                    selectedVariantIndex = index;
                  });
                },
                imageUrls: imageUrls,
              ),
              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }

  // Image Carousel
  Widget buildImageCarousel(List<String> imageUrls) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 320,
            width: 340,
            child: PageView.builder(
              controller: _pageController,
              itemCount: imageUrls.length,
              onPageChanged: (index) => setState(() => _selectedImage = index),
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.broken_image, size: 200),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageUrls.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _selectedImage == index ? Colors.white : Colors.white54,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final int totalPages = widget.productData['imageUrls']?.length ?? 1;
      final int nextPage = (_selectedImage + 1) % totalPages;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      setState(() {
        _selectedImage = nextPage;
      });
    });
  }

  //
  Widget buildProductPriceRow({
    required String name,
    required double price,
    double? oldPrice,
  }) {
    final int discountPercent =
    (oldPrice != null && oldPrice > 0)
        ? (((oldPrice - price) / oldPrice) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              "₹$price",
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(width: 10),
            if (oldPrice != null)
              Text(
                "₹$oldPrice",
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            const SizedBox(width: 10),
            if (oldPrice != null)
              Text(
                '$discountPercent% OFF',
                style: const TextStyle(color: Colors.green, fontSize: 14),
              ),
          ],
        ),
      ],
    );
  }

  void showPriceDetailsBottomSheet({
    required BuildContext context,
    required double price,
    double? oldPrice,
  }) {
    final int savings = (oldPrice != null) ? (oldPrice - price).round() : 0;
    final int discountPercent =
    oldPrice != null && oldPrice > 0
        ? ((savings / oldPrice) * 100).round()
        : 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.remove, size: 32, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                "Price Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                title: const Text("Maximum Retail Price"),
                subtitle: const Text("(Inclusive of all taxes)"),
                trailing: Text(
                  "₹${oldPrice?.toInt() ?? price.toInt()}",
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              ListTile(
                title: const Text("Selling Price"),
                trailing: Text(
                  "₹${price.toInt()}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              if (oldPrice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    "You save ₹$savings ($discountPercent%) on this product",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildVariantSelector({
    required List<Map<String, dynamic>> variants,
    required int selectedIndex,
    required void Function(int) onVariantSelected,
    required List<String> imageUrls,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
        variants.asMap().entries.map((entry) {
          final int index = entry.key;
          final variant = entry.value;
          final bool isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onVariantSelected(index),
            child: Container(
              width: 100,
              height: 150,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
                color: isSelected ? Colors.red.shade50 : Colors.white,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      variant['image'] ?? imageUrls.first,
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('${variant['weight']}'),
                  Text(
                    '₹${variant['price']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

}
