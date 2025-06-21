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
            children: [buildImageCarousel(imageUrls)],
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
}
