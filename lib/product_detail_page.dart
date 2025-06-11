import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joy_a_more_test/product_model.dart';

import 'free_message_card_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedImage = 0;
  late PageController _pageController;
  Timer? _autoScrollTimer;
  String? _deliveryLocation = "Detecting location...";
  int selectedVariantIndex = 0;
  Map<String, dynamic>? selectedCardData;

  // Price
  Widget _buildProductPriceRow({
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

  // Variant
  Widget _buildVariantSelector({
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

  // Location
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

  Future<void> _changeLocationManually() async {
    final pinCodeController = TextEditingController();

    // Allowed Gonda pincodes (you can update this list)
    final allowedPincodes = ['271001', '271002', '271003', '271301'];

    // Step 1: Ask for pincode first
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
                  await _showFullAddressForm(enteredPin);
                },
                child: const Text("Check"),
              ),
            ],
          ),
    );
  }

  Future<void> _showFullAddressForm(String postalCode) async {
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

  // Delivery Date & Time
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<String> _generateTimeSlotsForDate(DateTime selectedDate) {
    final now = DateTime.now();
    final slots = <String>[];

    for (int hour = 10; hour < 22; hour++) {
      final slotStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
      );

      final label = "${_formatTime(hour)} – ${_formatTime(hour + 1)}";

      // Enforce 2-hour future rule if slot is today
      if (slotStart.isAfter(now.add(const Duration(hours: 2)))) {
        slots.add(label);
      } else if (selectedDate.day != now.day ||
          selectedDate.month != now.month ||
          selectedDate.year != now.year) {
        slots.add(label);
      }
    }

    return slots;
  }

  String _formatTime(int hour) {
    final h = hour > 12 ? hour - 12 : hour;
    final suffix = hour >= 12 ? "PM" : "AM";
    return "${h.toString().padLeft(2, '0')}:00 $suffix";
  }

  Widget _buildDeliveryDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Select Delivery Date & Time",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Date Picker
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  DateTime now = DateTime.now();
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _selectedTimeSlot = null;
                    });
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  _selectedDate != null
                      ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                      : "Pick Date",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Time Slot Dropdown
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select a date first"),
                      ),
                    );
                    return;
                  }

                  List<String> slots = _generateTimeSlotsForDate(
                    _selectedDate!,
                  );
                  String? selected = await showModalBottomSheet<String>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder:
                        (context) => ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          children:
                              slots.map((slot) {
                                return ListTile(
                                  title: Text(slot),
                                  onTap: () => Navigator.pop(context, slot),
                                );
                              }).toList(),
                        ),
                  );

                  if (selected != null) {
                    setState(() => _selectedTimeSlot = selected);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTimeSlot ?? "Pick Time Slot",
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Confirmation message
        if (_selectedDate != null && _selectedTimeSlot != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              "Selected: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • $_selectedTimeSlot",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // Messages
  String? _cakeMessage;
  Widget _buildMessageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add Messages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),

        // 🎂 Cake Message Button
        ElevatedButton.icon(
          icon: const Icon(Icons.cake),
          label: Text(
            _cakeMessage != null ? "Edit Cake Message" : "Message on Cake",
          ),
          onPressed: _showCakeMessageDialog,
        ),

        // 🎂 Cake Message Summary Box
        if (_cakeMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🎂 ", style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    "Cake Message: $_cakeMessage",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // 📝 Free Message Card Button
        ElevatedButton.icon(
          icon: const Icon(Icons.card_giftcard),
          label: const Text("Add Free Message Card"),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FreeMessageCardPage()),
            );

            if (result != null && result is Map<String, dynamic>) {
              setState(() {
                selectedCardData = result;
              });
            }
          },
        ),

        const SizedBox(height: 12),

        // 📝 Free Message Card Summary Box
        if (selectedCardData != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Occasion: ${selectedCardData!['occasion']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Message: ${selectedCardData!['message'].toString().length > 40 ? "${selectedCardData!['message'].toString().substring(0, 40)}..." : selectedCardData!['message']}",
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showCakeMessageDialog() {
    TextEditingController controller = TextEditingController(
      text: _cakeMessage,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Message on Cake"),
            content: TextField(
              controller: controller,
              maxLength: 30,
              decoration: const InputDecoration(
                hintText: "Enter message (max 30 chars)",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _cakeMessage = controller.text.trim());
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  // About the products
  int? expandedTileIndex;
  Widget buildAboutExpandableTilesSection(Map<String, dynamic> product) {
    // Safely extract list fields or fallback to an empty list
    final List<String> productDescription = List<String>.from(
      product['productDescription'] ?? [],
    );
    final List<String> careInstruction = List<String>.from(
      product['careInstruction'] ?? [],
    );
    final List<String> deliveryInformation = List<String>.from(
      product['deliveryInformation'] ?? [],
    );

    final List<Map<String, dynamic>> dynamicTiles = [
      {
        "title": "Product Description",
        "icon": Icons.assignment,
        "content": productDescription,
      },
      {
        "title": "Care Instructions",
        "icon": Icons.insert_chart,
        "content": careInstruction,
      },
      {
        "title": "Delivery Information",
        "icon": Icons.local_shipping,
        "content": deliveryInformation,
      },
    ];

    return Container(
      color: const Color(0xFFF9F9F4),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              "About the product",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(dynamicTiles.length, (index) {
            final tile = dynamicTiles[index];
            final isExpanded = expandedTileIndex == index;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Icon(tile["icon"], color: Colors.green.shade800),
                    title: Text(
                      tile["title"],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Icon(isExpanded ? Icons.close : Icons.add),
                    onTap: () {
                      expandedTileIndex = isExpanded ? null : index;
                      // Use StatefulBuilder or make expandedTileIndex a State variable
                      (this as dynamic).setState(() {});
                    },
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            (tile["content"] as List<String>).map((line) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "• ",
                                      style: TextStyle(height: 1.5),
                                    ),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: const TextStyle(height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Product reviews
  late Future<List<Review>> _reviewsFuture;

  Future<List<Review>> fetchProductReviews(String productId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

    if (!doc.exists) return [];

    final data = doc.data();
    if (data == null || data['reviews'] == null) return [];

    final List<dynamic> reviewList = data['reviews'];

    return reviewList
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // sort newest first
  }

  Widget buildReviewSlider(List<Review> reviews) {
    if (reviews.isEmpty) {
      return const Text("No reviews yet.");
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.comment,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  "${review.occasion} • ${review.place}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
    _getCurrentLocation();
    _reviewsFuture = fetchProductReviews(widget.product['id']);
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_pageController.hasClients && mounted) {
        final int nextPage =
            ((_selectedImage + 1) % (widget.product['imageUrls']?.length ?? 1))
                .toInt();
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _selectedImage = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrls = List<String>.from(product['imageUrls'] ?? []);
    final variants = List<Map<String, dynamic>>.from(
      product['extraAttributes']?['variants'] ?? [],
    );
    final name = product['name'] ?? '';
    final selectedVariant = variants[selectedVariantIndex];
    final double price = (selectedVariant['price'] as num).toDouble();
    final double? oldPrice =
        selectedVariant['oldPrice'] != null
            ? (selectedVariant['oldPrice'] as num).toDouble()
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Detail"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Auto-scrolling Image Carousel with padding + rounded corners
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 320,
                      width: 320,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: imageUrls.length,
                        onPageChanged:
                            (index) => setState(() => _selectedImage = index),
                        itemBuilder: (context, index) {
                          return Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 200),
                          );
                        },
                      ),
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
                              _selectedImage == index
                                  ? Colors.white
                                  : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name and pricing
                  _buildProductPriceRow(
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
                  const SizedBox(height: 10),

                  // Variant Selector
                  _buildVariantSelector(
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

                  // Delivery Location
                  buildDeliveryLocationCard(
                    context: context,
                    deliveryLocation: _deliveryLocation,
                    onChangePressed: () => _showLocationOptions(context),
                  ),

                  // Delivery date & time
                  _buildDeliveryDateTimePicker(),
                  const SizedBox(height: 20),

                  // Cake Message & Card Message
                  _buildMessageSection(context),
                  const SizedBox(height: 20),

                  // About the product
                  buildAboutExpandableTilesSection(widget.product),

                  // Product reviews
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Customer Reviews",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<Review>>(
                          future: _reviewsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Text("Failed to load reviews");
                            }
                            return buildReviewSlider(snapshot.data ?? []);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              // Add to cart logic
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart),
                SizedBox(width: 10),
                const Text(
                  "Add to Cart",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
