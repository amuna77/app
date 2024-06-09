import 'package:cloud_firestore/cloud_firestore.dart';

class CategorySrevices {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateCategory(String categoryId, Map<String, dynamic> newData) async {
    try {
       await firestore.collection('categories').doc(categoryId).update(newData);
      print('Category updated successfully: $categoryId');
    } catch (error) {
      print('Error updating category: $error');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try{
      CollectionReference products = firestore.collection('categories');

      await products.doc(id).delete();

      print('Category deleted succesfully');
      
    }catch(e) {
      print('Error deleting category: $e');

    }
  }
  
  
}


