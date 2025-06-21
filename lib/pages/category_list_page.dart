import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:joy_a_more_test/pages/sub_category_page.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  String convertDriveLinkToDirect(String url) {
    final match = RegExp(r'd/([^/]+)').firstMatch(url);
    if (url.contains("drive.google.com/file/d/") && match != null) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url;
  }

  bool isTopLevelCategory(Map<String, dynamic> data) {
    final categoryId = data['categoryId'];
    return categoryId == null || categoryId.toString().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Categories"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .orderBy('priority', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading categories"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final topLevelDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return isTopLevelCategory(data);
          }).toList();

          if (topLevelDocs.isEmpty) {
            return const Center(child: Text("No top-level categories found."));
          }

          return ListView.builder(
            itemCount: topLevelDocs.length,
            itemBuilder: (context, index) {
              final data = topLevelDocs[index].data() as Map<String, dynamic>;

              final id = data['id'] ?? '';
              final name = data['name'] ?? 'Unnamed';
              final imageUrl = data['imageUrl'] ?? '';
              final description = data['description'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      convertDriveLinkToDirect(imageUrl),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 36),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(description),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubCategoryPage(
                          parentCategoryId: id,
                          parentCategoryName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}