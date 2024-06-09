import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:my_application/client/pages/checkout.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> productDetailsList = [];
  bool _isLoading = false;
  double discountPercentage = 0.0;
  double newTotalAfterDiscount = 0.0;

  double total = 0.0;

  double calculateTotalPrice() {
    double total = 0.0;
    for (var productDetail in productDetailsList) {
      total += (productDetail['productPrice'] * productDetail['quantity']);
    }
    return total;
  }

  Future<bool> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return false;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
        });
        return false;
      }
    }

    _locationData = await location.getLocation();
    setState(() {
      _isLoading = false;
    });
    return true;
  }

  @override
  void initState() {
    super.initState();
    loadProductDetails();
    cleanUpCart();
  }

  // ...
  Future<void> handleQuantityChange(String detailId, int newQuantity) async {
    await updateQuantity(detailId, newQuantity);

    await checkAndDeleteProductIfZero(detailId);
  }

  Future<void> clearAll() async {
    var cartSnapshot = await FirebaseFirestore.instance
        .collection('Cart')
        .where('clients', isEqualTo: _auth.currentUser?.uid)
        .where('checkout', isEqualTo: false)
        .get();

    for (var cartItem in cartSnapshot.docs) {
      var idCart = cartItem.id;
      var detailSnapshot = await FirebaseFirestore.instance
          .collection('details')
          .where('id_cart', isEqualTo: idCart)
          .get();

      for (var doc in detailSnapshot.docs) {
        int quantity = (doc.data() as Map<String, dynamic>)['quantite'] ?? 0;

        String id_produit =
            (doc.data() as Map<String, dynamic>)['id_produit'] ?? 0;
        DocumentSnapshot product = await FirebaseFirestore.instance
            .collection('products')
            .doc(id_produit)
            .get();

        if (product.exists) {
          int currentQuantity =
              (product.data() as Map<String, dynamic>?)?['quantity'] ?? 0;

          await FirebaseFirestore.instance
              .collection('products')
              .doc(id_produit)
              .update({
            'quantity': currentQuantity + quantity,
          });
        }

        await doc.reference.delete();
      }

      for (var doc in detailSnapshot.docs) {
        await cartItem.reference.delete();
      }
    }

    productDetailsList.clear();
    setState(() {});
  }

  Future<void> loadProductDetails() async {
    var cartSnapshot = await FirebaseFirestore.instance
        .collection('Cart')
        .where('clients', isEqualTo: _auth.currentUser?.uid)
        .where('checkout', isEqualTo: false)
        .get();

    for (var cartItem in cartSnapshot.docs) {
      var idCart = cartItem.id;
      var detailSnapshot = await FirebaseFirestore.instance
          .collection('details')
          .where('id_cart', isEqualTo: idCart)
          .get();

      for (var doc in detailSnapshot.docs) {
        var productId = doc['id_produit'];
        var productSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        var productData = productSnapshot.data() as Map<String, dynamic>;
        productDetailsList.add({
          'detailId': doc.id,
          'productId': productId,
          'productName': productData['name'],
          'productPrice': doc['unit_price'],
          'productImage': productData['image'],
          'quantity': doc['quantite'],
          'total_price': doc['total_price'],
          'doc': doc,
        });
      }
    }

    setState(() {}); // Rebuild the widget after loading data
  }

  Future<void> updateQuantity(String detailId, int newQuantity) async {
    await FirebaseFirestore.instance
        .collection('details')
        .doc(detailId)
        .update({'quantite': newQuantity});
  }

  Future<void> checkAndDeleteProductIfZero(String detailId) async {
    try {
      var detailSnapshot = await FirebaseFirestore.instance
          .collection('details')
          .doc(detailId)
          .get();

      if (detailSnapshot.exists) {
        var quantity = detailSnapshot['quantite'];

        if (quantity == 0) {
          await detailSnapshot.reference.delete();

          productDetailsList
              .removeWhere((item) => item['detailId'] == detailId);
          setState(() {});
        }
      }
    } catch (e) {
      print(
          "Erreur lors de la vérification et de la suppression du produit : $e");
    }
  }

  Future<Map<String, dynamic>> applyDiscountIfApplicable(double total) async {
    // Récupérer les données de Firestore pour la réduction
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('reduction').get();

    for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
      Map<String, dynamic> reductionData = documentSnapshot.data()
          as Map<String, dynamic>; // Convertir les données en Map

      // Vérifier si les données de réduction ne sont pas vides
      if (reductionData.isNotEmpty) {
        // Récupérer le discountedPrice et le pourcentage de la réduction
        double? discountedPrice = reductionData['discountedPrice']?.toDouble();
        double? percentage = reductionData['percentage']?.toDouble();

        // Vérifier si le total correspond au discountedPrice
        if (total == discountedPrice) {
          // Calculer le montant de la réduction
          double discountAmount = total * (percentage! / 100);
          // Calculer le nouveau total après réduction
          total = total - discountAmount;
          updateCartTotalPriceForClient(total, 0.0);
          // Afficher les détails de la réduction dans la console
          print('Pourcentage de réduction appliqué : $percentage%');
          print(
              'Nouveau total après réduction : \$${total.toStringAsFixed(2)}');
          updateCartTotalPriceForClient(total, percentage);
          // Retourner le nouveau total et le pourcentage de réduction
          return {'newTotal': total, 'percentage': percentage};
        }
      }
    }

    // Si aucun discountedPrice correspondant n'est trouvé, retourner le total original
    return {'newTotal': total, 'percentage': 0.0};
  }

  Future<void> updateCartTotalPriceForClient(
      double total, double percentage) async {
    try {
      // Vérifier si un utilisateur est connecté
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Récupérer l'identifiant du client connecté
        String currentUserId = user.uid;

        // Créer un Timestamp à partir de la date actuelle
        Timestamp currentTimestampFirestore = Timestamp.now();

        // Effectuer la requête pour trouver le document Cart correspondant
        QuerySnapshot cartQuery = await FirebaseFirestore.instance
            .collection('Cart')
            .where('clients', isEqualTo: currentUserId)
            .where('checkout', isEqualTo: false)
            .get();

        // Vérifier si des documents ont été trouvés
        if (cartQuery.docs.isNotEmpty) {
          // Récupérer le premier document trouvé
          DocumentSnapshot cartDoc = cartQuery.docs.first;

          // Mettre à jour le total_price avec la valeur fournie
          await cartDoc.reference.update({
            'total_price': total,
            'percentage': percentage,
          });
        } else {
          // Aucun document trouvé correspondant aux critères de recherche
          print('Aucun panier trouvé pour ce client et ce timestamp.');
        }
      } else {
        // Aucun utilisateur n'est connecté
        print('Aucun utilisateur connecté.');
      }
    } catch (e) {
      print("Erreur lors de la mise à jour du total_price du panier : $e");
      throw e;
    }
  }

  Future<void> cleanUpCart() async {
    try {
      // Récupérer tous les documents de la collection Cart
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('Cart')
          .where('clients',
              isEqualTo:
                  _auth.currentUser?.uid) // Remplacez par l'ID du client actuel
          .get();

      for (QueryDocumentSnapshot cartDoc in cartSnapshot.docs) {
        String cartId = cartDoc.id;

        // Vérifier s'il existe un document dans la collection details avec id_cart == cartId
        QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
            .collection('details')
            .where('id_cart', isEqualTo: cartId)
            .get();

        if (detailsSnapshot.docs.isEmpty) {
          // Si aucun document trouvé, supprimer le document de la collection Cart
          await cartDoc.reference.delete();
        }
      }
    } catch (e) {
      print('Erreur lors du nettoyage du panier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = calculateTotalPrice(); // Calcul du total
    Future<Map<String, dynamic>> discountInfo =
        applyDiscountIfApplicable(total);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سلة التسوق',
          style: TextStyle(
            fontSize: 24, // Augmentation de la taille de la police
            fontWeight: FontWeight.bold, // Police en gras
            color: Colors.white, // Couleur de texte blanc
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : productDetailsList.isEmpty
                ? Center(
                    child: Text(
                      'سلة التسوق الخاصة بك فارغة',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : FutureBuilder<Map<String, dynamic>>(
                    future: discountInfo,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        bool hasDiscount = snapshot.data?['newTotal'] != total;
                        double newTotal = snapshot.data?['newTotal'] ?? total;
                        double percentage = snapshot.data?['percentage'] ?? 0.0;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      clearAll();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 220),
                                      child: InkWell(
                                        onTap: () {
                                          clearAll();
                                        },
                                        child: Text(
                                          'مسح الكل',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.red, // Couleur rouge
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: productDetailsList.length,
                              itemBuilder: (context, index) {
                                var productDetail = productDetailsList[index];
                                return Dismissible(
                                  key: UniqueKey(),
                                  onDismissed: (direction) async {
                                    var detailId = productDetail['detailId'];
                                    var cartItem = await FirebaseFirestore
                                        .instance
                                        .collection('details')
                                        .doc(detailId)
                                        .get();
                                    await cartItem.reference.delete();

                                    double total_price =
                                        detailId['total_price'] ?? 0.0;

                                    DocumentSnapshot<Map<String, dynamic>>
                                        cartDocument = await FirebaseFirestore
                                            .instance
                                            .collection('Cart')
                                            .doc(cartItem.id)
                                            .get();

                                    if (cartDocument.exists) {
                                      double ancien_total =
                                          cartDocument.data()!['total_price'] ??
                                              0.0;
                                      await cartDocument.reference.update({
                                        'total_price':
                                            ancien_total + total_price,
                                      });
                                    }
                                    setState(() {
                                      productDetailsList.removeAt(index);
                                    });
                                  },
                                  background: Container(
                                    color: Colors.red,
                                    child: Icon(Icons.delete,
                                        color: Colors.white, size: 40),
                                    alignment: Alignment.centerRight,
                                    padding: EdgeInsets.only(right: 20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.network(
                                            productDetail['productImage'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productDetail['productName'],
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(
                                                    'السعر: ',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    '${productDetail['productPrice']}',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () async {
                                                      var quantity =
                                                          productDetail[
                                                              'quantity'];
                                                      if (quantity > 0) {
                                                        setState(() {
                                                          quantity--;
                                                        });
                                                        _incrementQuantityInStock(
                                                            productDetail[
                                                                'productId'],
                                                            productDetail);
                                                        await updateQuantity(
                                                            productDetail[
                                                                'detailId'],
                                                            quantity);
                                                        await handleQuantityChange(
                                                            productDetail[
                                                                'detailId'],
                                                            quantity);
                                                        setState(() {
                                                          productDetailsList[
                                                                      index]
                                                                  ['quantity'] =
                                                              quantity;
                                                        });
                                                      }
                                                    },
                                                    icon: Icon(Icons.remove),
                                                  ),
                                                  Text(
                                                    '${productDetail['quantity']}',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      var quantity =
                                                          productDetail[
                                                              'quantity'];
                                                      print(quantity);
                                                      String id_produit =
                                                          productDetail[
                                                              'productId'];

                                                      DocumentSnapshot
                                                          products =
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'products')
                                                              .doc(id_produit)
                                                              .get();

                                                      if (products.exists) {
                                                        print('exist');
                                                        int currentQuantity =
                                                            products[
                                                                    'quantity'] ??
                                                                0;
                                                        int scure_quantity =
                                                            products[
                                                                    'secureQuantity'] ??
                                                                0;
                                                        print(currentQuantity);
                                                        print(scure_quantity);
                                                        if (currentQuantity >
                                                            scure_quantity) {
                                                          print('yes');
                                                          setState(() {
                                                            quantity++;
                                                          });
                                                        }
                                                      }
                                                      _decrementQuantityInStock(
                                                          productDetail[
                                                              'productId'],
                                                          productDetail);
                                                      await updateQuantity(
                                                          productDetail[
                                                              'detailId'],
                                                          quantity);
                                                      await handleQuantityChange(
                                                          productDetail[
                                                              'detailId'],
                                                          quantity);
                                                      setState(() {
                                                        productDetailsList[
                                                                    index]
                                                                ['quantity'] =
                                                            quantity;
                                                      });
                                                    },
                                                    icon: Icon(Icons.add),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            var detail = productDetail['doc'];

                                            var quantity =
                                                productDetail['quantity'];
                                            print(quantity);
                                            String id_produit =
                                                productDetail['productId'];

                                            DocumentSnapshot products =
                                                await FirebaseFirestore.instance
                                                    .collection('products')
                                                    .doc(id_produit)
                                                    .get();

                                            if (products.exists) {
                                              print('exist');
                                              int currentQuantity =
                                                  products['quantity'] ?? 0;

                                              await FirebaseFirestore.instance
                                                  .collection('products')
                                                  .doc(id_produit)
                                                  .update({
                                                'quantity':
                                                    currentQuantity + quantity,
                                              });
                                            }

                                            var details =
                                                await FirebaseFirestore.instance
                                                    .collection('details')
                                                    .doc(detail.id)
                                                    .get();

                                            double total_price = details
                                                    .data()?['total_price'] ??
                                                0.0;
                                            String cartId =
                                                details.data()?['id_cart'] ??
                                                    '';

                                            DocumentReference cartDocRef =
                                                FirebaseFirestore.instance
                                                    .collection('Cart')
                                                    .doc(cartId);
                                            DocumentSnapshot cartDoc =
                                                await cartDocRef.get();
                                            double ancienTotal =
                                                cartDoc['total_price'];

// Ajouter le nouveau montant à l'ancien total
                                            double newTotal =
                                                ancienTotal - total_price;

// Mettre à jour le champ total_price avec le nouveau total
                                            await cartDocRef.update({
                                              'total_price': newTotal,
                                            });

                                            await details.reference.delete();
                                            setState(() {
                                              productDetailsList
                                                  .removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  hasDiscount
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'التخفيض: ${percentage.toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'الإجمالي الجديد: \$${newTotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          '   ${total.toStringAsFixed(2)} DA   : الإجمالي   ',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: ElevatedButton(
            onPressed: () async {
              if (calculateTotalPrice() == 0.0) {
                showEmptyCartAlert();
              } else {
                bool hasPermission = await _requestLocationPermission();
                if (hasPermission) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CheckoutScreen()),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('الإذن مطلوب'),
                      content: Text(
                          'الرجاء السماح للتطبيق بالوصول إلى موقعك لمتابعة عملية الدفع.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('موافق'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                  Color.fromARGB(255, 199, 222, 146)), // Couleur de fond bleu
              elevation: MaterialStateProperty.all(8), // Élévation réduite
              shadowColor:
                  MaterialStateProperty.all(Colors.black), // Ombre noire
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      12.0), // Bordure légèrement arrondie
                ),
              ),
              minimumSize: MaterialStateProperty.all(
                  Size(double.infinity, 50)), // Largeur infinie et hauteur 50
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    color: const Color.fromARGB(
                        255, 32, 30, 30)), // Icône de chariot avec outline
                SizedBox(width: 10), // Espacement entre l'icône et le texte
                Text(
                  'تأكيد الطلبية', // Changement du texte du bouton
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(
                        255, 15, 15, 15), // Couleur de texte blanc
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _incrementQuantityInStock(
      String productId, Map<String, dynamic> productDetail) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final DocumentSnapshot productSnapshot = await FirebaseFirestore
            .instance
            .collection('products')
            .doc(productId)
            .get();

        if (productSnapshot.exists) {
          int currentQuantity = productSnapshot['quantity'] ?? 0;
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .update({
            'quantity': currentQuantity + 1,
          });

          await productSnapshot.reference.update({
            'quantity': currentQuantity + 1,
          });
        }

        QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
            .collection('Cart')
            .where('clients', isEqualTo: user.uid)
            .where('checkout', isEqualTo: false)
            .get();
        String cartId;
        if (cartSnapshot.docs.isNotEmpty) {
          cartId = cartSnapshot.docs.first.id;

          QuerySnapshot Details = await FirebaseFirestore.instance
              .collection('details')
              .where('id_produit', isEqualTo: productId)
              .where('id_cart', isEqualTo: cartId)
              .get();
          String detailsid = '';
          if (cartSnapshot.docs.isNotEmpty) {
            detailsid = Details.docs.first.id;

            Details.docs.forEach((doc) async {
              double unitPrice = doc['unit_price'];
              int quantite = doc['quantite'];
              double new_total = unitPrice * quantite;
              await FirebaseFirestore.instance
                  .collection('details')
                  .doc(detailsid)
                  .update({
                'total_price': new_total,
              });

              DocumentReference cartDocRef =
                  FirebaseFirestore.instance.collection('Cart').doc(cartId);
              DocumentSnapshot cartDoc = await cartDocRef.get();
              double ancienTotal = cartDoc['total_price'];

// Ajouter le nouveau montant à l'ancien total
              double newTotal = ancienTotal - unitPrice;

// Mettre à jour le champ total_price avec le nouveau total
              await cartDocRef.update({
                'total_price': newTotal,
              });
            });
          }
        }
      } catch (e) {
        print("Erreur lors de l'incrémentation de la quantité : $e");
      }
    }
  }

  void _decrementQuantityInStock(
      String productId, Map<String, dynamic> productDetail) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot ligneFactureSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (ligneFactureSnapshot.exists) {
        int currentQuantity = ligneFactureSnapshot['quantity'] ?? 0;
        int scure_quantity = ligneFactureSnapshot['secureQuantity'] ?? 0;

        if (currentQuantity > scure_quantity) {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId) // Utilisez plutôt productId ici
              .update({
            'quantity': currentQuantity - 1,
          });

          QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
              .collection('Cart')
              .where('clients', isEqualTo: user.uid)
              .where('checkout', isEqualTo: false)
              .get();
          String cartId;
          if (cartSnapshot.docs.isNotEmpty) {
            cartId = cartSnapshot.docs.first.id;

            QuerySnapshot Details = await FirebaseFirestore.instance
                .collection('details')
                .where('id_produit', isEqualTo: productId)
                .where('id_cart', isEqualTo: cartId)
                .get();
            String detailsid = '';
            if (cartSnapshot.docs.isNotEmpty) {
              detailsid = Details.docs.first.id;

              Details.docs.forEach((doc) async {
                double unitPrice = doc['unit_price'];
                int quantite = doc['quantite'];
                double new_total = unitPrice * quantite;
                await FirebaseFirestore.instance
                    .collection('details')
                    .doc(detailsid)
                    .update({
                  'total_price': new_total,
                });

                DocumentReference cartDocRef =
                    FirebaseFirestore.instance.collection('Cart').doc(cartId);
                DocumentSnapshot cartDoc = await cartDocRef.get();
                double ancienTotal = cartDoc['total_price'];

// Ajouter le nouveau montant à l'ancien total
                double newTotal = ancienTotal + unitPrice;

// Mettre à jour le champ total_price avec le nouveau total
                await cartDocRef.update({
                  'total_price': newTotal,
                });
              });
            }
          }
        } else {
          print("Out of Stock");

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Out of Stock'),
                content: Text('The quantity is now 0.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }
}

void showEmptyCartAlert() {
  Fluttertoast.showToast(
    msg: "Il faut commander des produits",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
