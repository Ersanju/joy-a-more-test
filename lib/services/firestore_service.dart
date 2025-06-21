import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/product.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Fetch top level categories
  Future<List<Category>> getTopLevelCategories() async {
    final snapshot = await _db.collection('categories').orderBy('priority').get();

    return snapshot.docs
        .where((doc) {
      final data = doc.data();
      final categoryId = data['categoryId'];
      return categoryId == null || categoryId.toString().isEmpty;
    })
        .map((doc) => Category.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Fetch subcategories for given category id
  Future<List<Category>> getSubCategories(String parentId) async {
    final snapshot = await _db.collection('categories')
        .where('categoryId', isEqualTo: parentId)
        .orderBy('priority')
        .get();

    return snapshot.docs
        .map((doc) => Category.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Fetch products for given subCategoryId
  Future<List<Product>> getProductsBySubCategory(String subCategoryId) async {
    final snapshot = await _db.collection('cake_product')
        .where('categoryIds', arrayContains: subCategoryId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
