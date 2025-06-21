import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedImage = 0;
  late PageController _pageController;
  int _selectedVariantIndex = 0;
  Timer? _autoScrollTimer;
  String? _deliveryLocation = "Detecting location...";

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
    _getCurrentLocation();
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
      widget.productData['extraAttributes']?['cakeAttribute']?['variants'] ??
          [],
    );
    final selectedVariant = variants[_selectedVariantIndex];
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
                selectedIndex: _selectedVariantIndex,
                onVariantSelected: (index) {
                  setState(() {
                    _selectedVariantIndex = index;
                  });
                },
                imageUrls: imageUrls,
              ),
              const SizedBox(height: 20),

              // Delivery Location
              buildDeliveryLocationCard(
                context: context,
                deliveryLocation: _deliveryLocation,
                onChangePressed: () => _showLocationOptions(context),
              ),
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

  // Name, Price
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

  // Product variants
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

  // Delivery location
  Widget buildDeliveryLocationCard({
    required BuildContext context,
    required String? deliveryLocation,
    required VoidCallback onChangePressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Deliver to:",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deliveryLocation ?? "No location selected",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onChangePressed,
            label: const Text(
              "Change",
              style: TextStyle(color: Colors.blueAccent),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  "Update Delivery Location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.my_location,
                    color: Colors.deepPurple,
                  ),
                  title: const Text("Use Current Location"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _getCurrentLocation();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.edit_location_alt,
                    color: Colors.deepPurple,
                  ),
                  title: const Text("Enter Manually"),
                  onTap: () {
                    Navigator.pop(context);
                    _changeLocationManually();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _deliveryLocation = "Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _deliveryLocation = "Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
        () => _deliveryLocation = "Location permission permanently denied.",
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final place = placemarks.first;
    setState(() {
      _deliveryLocation =
          "${place.name}, ${place.subLocality}, ${place.locality}, \n ${place.subAdministrativeArea}, ${place.postalCode}";
    });
  }

  Future<void> _changeLocationManually() async {
    final pinCodeController = TextEditingController();

    // Allowed Gonda pincodes (you can update this list)
    final allowedPincodes = ['271001', '271002', '271003', '271304', '271305'];

    // Step 1: Ask for pin code first
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Check for your location"),
            content: TextField(
              controller: pinCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: "Enter 6-digit postal code",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final enteredPin = pinCodeController.text.trim();

                  if (enteredPin.length != 6 ||
                      !RegExp(r'^\d{6}$').hasMatch(enteredPin)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter valid 6-digit postal code"),
                      ),
                    );
                    return;
                  }

                  if (!allowedPincodes.contains(enteredPin)) {
                    Navigator.pop(context);
                    await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("Not Operational"),
                            content: const Text(
                              "We are not delivering at this location yet.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                    );
                    return;
                  }

                  Navigator.pop(context); // Close pin code dialog

                  // Step 2: Continue with full address form
                  await showFullAddressForm(enteredPin);
                },
                child: const Text("Check"),
              ),
            ],
          ),
    );
  }

  Future<void> showFullAddressForm(String postalCode) async {
    final formKey = GlobalKey<FormState>();
    final address1Controller = TextEditingController();
    final address2Controller = TextEditingController();
    final areaController = TextEditingController();
    final districtController = TextEditingController(text: "Gonda");
    final stateController = TextEditingController(text: "Uttar Pradesh");

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Enter Delivery Details"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: address1Controller,
                      decoration: const InputDecoration(
                        labelText: "Address Line 1",
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                    TextFormField(
                      controller: address2Controller,
                      decoration: const InputDecoration(
                        labelText: "Address Line 2",
                      ),
                    ),
                    TextFormField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: "Area / Locality",
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                    TextFormField(
                      controller: districtController,
                      decoration: const InputDecoration(labelText: "District"),
                      enabled: false,
                    ),
                    TextFormField(
                      controller: stateController,
                      decoration: const InputDecoration(labelText: "State"),
                      enabled: false,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Postal Code",
                      ),
                      initialValue: postalCode,
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      _deliveryLocation =
                          "${address1Controller.text}, ${address2Controller.text}, ${areaController.text}, Gonda, Uttar Pradesh - $postalCode";
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Update"),
              ),
            ],
          ),
    );
  }
}
