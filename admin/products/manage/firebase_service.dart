import 'package:cloud_firestore/cloud_firestore.dart';

class ProductServices {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateProduct(
      String productId, Map<String, dynamic> newData) async {
    try {
      await firestore.collection('products').doc(productId).update(newData);
      print('Product updated successfully');
    } catch (error) {
      print('Error updating product: $error');
      throw error;
    }
  }

  Future<void> updateProducts(String productId, Map<String, dynamic> newData,
      int additionalQuantity, expirationDate, double purchasePrice) async {
    try {
      await firestore.collection('products').doc(productId).update(newData);

      DocumentReference productRef =
          firestore.collection('products').doc(productId);
      DocumentSnapshot productSnapshot = await productRef.get();

      if (productSnapshot.exists) {
        var data = productSnapshot.data() as Map<String, dynamic>;
        int currentQuantity = data['quantity'] ?? 0;
        await productRef
            .update({'quantity': currentQuantity + additionalQuantity});
        print('Product update successfully ID: $productId');
      } else {
        print('Product not found with ID: $productId');
        return;
      }
      if (additionalQuantity >= 0 && purchasePrice >= 0) {
        DocumentReference ligne_facture =
            await firestore.collection('detailProduct').add({
          'productId': productId,
          'quantity': additionalQuantity,
          'purchasePrice': purchasePrice,
          'purchaseDate': FieldValue.serverTimestamp(),
          'expirationDate': expirationDate,
        });
        print(' ligne_facture added successfully: ${ligne_facture.id} ');
      }

      print(' Product updated successfully: $productId ');
    } catch (e) {
      print('Error updating products: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      // Supprimer le produit de la collection 'products'
      await firestore.collection('products').doc(id).delete();

      // Récupérer les documents de la collection 'detailProduct' correspondant à l'ID du produit
      QuerySnapshot detailProductsSnapshot = await firestore
          .collection('detailProduct')
          .where('productId', isEqualTo: id)
          .get();

      // Parcourir les documents et les supprimer un par un
      for (DocumentSnapshot doc in detailProductsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('Product deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
    }
  }
}
// class ProductServices {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;

//   Future<void> updateProduct(String productId, Map<String, dynamic> newData) async {
//     try {
//       await firestore.collection('products').doc(productId).update(newData);
//     } catch (e) {
//       print('Error updating product: $e');
//     }
//   }

//   Future<void> updateProductQuantity(String productId, int additionalQuantity) async {
//     try {
//       final DocumentSnapshot productSnapshot = await firestore.collection('products').doc(productId).get();

//       if (productSnapshot.exists) {
//         final productData = productSnapshot.data() as Map<String, dynamic>;
//         int currentQuantity = productData['quantity'] ?? 0;

//         await firestore.collection('products').doc(productId).update({
//           'quantity': currentQuantity + additionalQuantity,
//         });
//       } else {
//         print('Product document does not exist for ID: $productId');
//       }
//     } catch (e) {
//       print('Error updating product quantity: $e');
//     }
//   }


//    Future<void> deleteProduct(String id) async {
//     try{
//       CollectionReference products = await firestore.collection('products');

//       await products.doc(id).delete();

//       print('Product deleted succesfully');
//     }catch(e) {
//       print('Error deleting product: $e');

//     }
//   }
// }
