import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:my_application/client/pages/display_products.dart';

import 'package:my_application/client/pages/notifications.dart';

import 'dart:async';

import 'package:my_application/client/pages/details.dart';
import 'package:my_application/client/pages/product_with_cat.dart';
import 'package:my_application/client/pages/search.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<void> updateLivreurReviews(String livreurId) async {
    final QuerySnapshot livreurReviewsSnapshot = await FirebaseFirestore
        .instance
        .collection('Cart')
        .where('id_livreur', isEqualTo: livreurId)
        .get();

    double totalReviews = 0;
    int reviewCount = livreurReviewsSnapshot.docs.length;

    livreurReviewsSnapshot.docs.forEach((doc) {
      totalReviews += (doc['reviews'] as num).toDouble();
    });

    double avgRating = reviewCount > 0 ? totalReviews / reviewCount : 0;

    await FirebaseFirestore.instance
        .collection('livreurs')
        .doc(livreurId)
        .update({'reviews': avgRating});
  }

  ValueNotifier<String?> selectedCategoryNotifier =
      ValueNotifier<String?>(null);
  String surname = '';
  Map<String, bool> isInWishlist = {};
  String? selectedCategory;
  Map<String, bool> favorites = {};
  Map<String, bool> cartItems = {};
  Map<String, bool> wishlistItems = {};
  TextEditingController searchController = TextEditingController();

  void notifierClient() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('Cart')
          .where('clients', isEqualTo: user.uid)
          .where('status', isEqualTo: 'preparation')
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        // Il y a une commande en préparation pour cet utilisateur
        // Récupérer l'id du livreur à partir du document de la commande
        String livreurId = result.docs.first['id_livreur'];

        // Rechercher les informations du livreur dans la collection "Livreur"
        QuerySnapshot livreurQuerySnapshot = await FirebaseFirestore.instance
            .collection('Livreurs')
            .where(FieldPath.documentId, isEqualTo: livreurId)
            .get();

        if (livreurQuerySnapshot.docs.isNotEmpty) {
          print('ok');
          // Livreur trouvé, obtenir le nom et le prénom
          String nomLivreur = livreurQuerySnapshot.docs.first['name'];
          String prenomLivreur = livreurQuerySnapshot.docs.first['surname'];

          // Construire le payload avec le nom et le prénom du livreur
          String payload = 'livré par $nomLivreur $prenomLivreur';

          // Afficher la notification
          //  showPeriodicNotifications(
          //   title: 'Nouvelle commande est acceptée',
          // body: 'Votre commande est en cours de préparation.',
          //payload: payload,
          //)//;
        }
      }
    }
  }

  Future<List<String>> getProductsByCondition() async {
    final today = DateTime.now();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Retrieve all products
    QuerySnapshot snapshot = await _firestore.collection('detailProduct').get();

    // Convert the snapshots to a list of documents
    List<DocumentSnapshot> documents = snapshot.docs;

    // Sort the documents based on the difference in days between 'expirationDate' and today,
    // and in case of equality, sort by purchase date (most recent first)
    documents.sort((a, b) {
      DateTime aExpDate = (a['expirationDate'] as Timestamp).toDate();
      DateTime bExpDate = (b['expirationDate'] as Timestamp).toDate();
      DateTime aPurchaseDate = (a['purchaseDate'] as Timestamp).toDate();
      DateTime bPurchaseDate = (b['purchaseDate'] as Timestamp).toDate();

      int differenceA = aExpDate.difference(today).inDays;
      int differenceB = bExpDate.difference(today).inDays;

      // If the expiration dates are the same, sort by the most recent purchase date
      if (differenceA == differenceB) {
        return bPurchaseDate.compareTo(aPurchaseDate);
      }

      // The document with the smallest difference will come first
      return differenceA.compareTo(differenceB);
    });

    // Use a Set to store unique product IDs
    Set<String> uniqueProductIds = {};

    // Collect unique product IDs from the sorted documents
    for (var doc in documents) {
      uniqueProductIds.add(doc['productId'] as String);

      DateTime docExpDate = (doc['expirationDate'] as Timestamp).toDate();
      int expDifference = docExpDate.difference(today).inDays;

      DateTime docPurchaseDate = (doc['purchaseDate'] as Timestamp).toDate();
      int purchaseDifference = docPurchaseDate.difference(today).inDays;

      print(
          'Document ID: ${doc.id}, Expiration Difference in days: $expDifference, Purchase Difference in days: $purchaseDifference');
    }

    // Convert the set to a list and return
    return uniqueProductIds.toList();
  }

  Widget showProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<String>>(
          future: getProductsByCondition(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text("No products");
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                String productId = snapshot.data![index];

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .snapshots(),
                  builder: (context, productSnapshot) {
                    if (!productSnapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    var productData =
                        productSnapshot.data!.data() as Map<String, dynamic>;

                    double? percentage = productData['percentage'] as double?;
                    double? sellingPrice;
                    double? oldPrice;

                    if (percentage != null) {
                      sellingPrice = (productData['price'] as double) -
                          ((productData['price'] as double) *
                              (percentage / 100));
                      oldPrice = productData['price'] as double;
                    }

                    bool isInWishlist = wishlistItems.containsKey(productId)
                        ? wishlistItems[productId]!
                        : false;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Details(
                              detail: productData['detail'],
                              image: productData['image'],
                              name: productData['name'],
                              price: percentage != null
                                  ? sellingPrice.toString()
                                  : productData['price'].toString(),
                              productID: productId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(productData['image']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    toggleFavorite(productId,
                                        !isInWishlist); // Inverse l'état actuel du favori
                                  },
                                  child: Container(
                                    margin: EdgeInsets.all(8),
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isInWishlist
                                          ? Colors.red.withOpacity(0.7)
                                          : Colors.white.withOpacity(0.7),
                                    ),
                                    child: Icon(
                                      isInWishlist
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isInWishlist
                                          ? Colors.white
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    percentage != null
                                        ? "$sellingPrice DA"
                                        : "${productData['price']} DA",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: percentage != null
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        SizedBox(height: 20.0),
      ],
    );
  }

  Widget buildProductWidget(Map<String, dynamic> productData,
      [double? percentage, double? sellingPrice]) {
    String productId = productData['id'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(
              detail: productData['detail'],
              image: productData['image'],
              name: productData['name'],
              price: percentage != null
                  ? "\$$sellingPrice"
                  : "\$${productData['price']}",
              productID: productId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                image: DecorationImage(
                  image: NetworkImage(productData['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productData['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    percentage != null
                        ? "\$$sellingPrice"
                        : "\$${productData['price']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: percentage != null ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showItem() {
    return StreamBuilder<QuerySnapshot<Object?>>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        List<DocumentSnapshot<Object?>> categories = snapshot.data!.docs;

        return Row(
          children: categories.map((category) {
            String categoryName = category['name'] as String;
            String categoryImage = category['image'] as String;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = categoryName;
                  selectedCategoryNotifier.value = categoryName;
                });
              },
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedCategoryNotifier.value == categoryName
                        ? Colors.black
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.all(15),
                  child: Image.network(
                    categoryImage,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.search), // Search icon
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchResultPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "  مرحبًا $surname ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NotificationPage()),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child:
                    showItem(), // Assurez-vous d'avoir une méthode nommée showItem()
              ),
              SizedBox(height: 20.0),
              if (selectedCategory != null)
                Expanded(
                  child: Center(
                    child: ProductDisplay(
                      selectedCategory: selectedCategory,
                    ),
                  ),
                ),
              if (selectedCategory == null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Products(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchProductDetails(
      String currentClientId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('historique_search')
        .where('id_client', isEqualTo: currentClientId)
        .get();

    List<Map<String, dynamic>> productDetails = [];

    for (var doc in snapshot.docs) {
      if (doc.data().containsKey('id_produit_prevu') &&
          doc['id_produit_prevu'] != null) {
        var productId = doc['id_produit_prevu'];
        var productSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (productSnapshot.exists) {
          var productData = productSnapshot.data() as Map<String, dynamic>;
          productDetails.add({
            'id': productId,
            'name': productData['name'],
            'image': productData['image'],
            'detail': productData['detail'],
            'price': productData['price'],
          });
        }
      }
    }

    return productDetails;
  }

  Future<void> getUserSurname() async {
    // Récupérer l'utilisateur actuellement connecté
    User? user = FirebaseAuth.instance.currentUser;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (user != null) {
      // Récupérer l'ID de l'utilisateur connecté
      String userId = user.uid;

      // Accéder au document utilisateur dans la collection 'clients'
      DocumentSnapshot<Object?> userSnapshot =
          await firestore.collection('clients').doc(userId).get();

      // Vérifier si le document existe
      if (userSnapshot.exists) {
        // Récupérer les données du document utilisateur
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        // Vérifier si les données sont disponibles
        if (userData != null) {
          // Récupérer le nom de famille à partir du document utilisateur
          setState(() {
            surname = userData['surname'];
          });
        } else {
          print('Données utilisateur non disponibles.');
        }
      } else {
        print('Document utilisateur non trouvé.');
      }
    } else {
      print('Utilisateur non connecté.');
    }
  }

  @override
  void initState() {
    super.initState();
    getUserSurname();
    fetchCartItems();
    fetchWishlistItems();
    notifierClient();

    final user = FirebaseAuth.instance.currentUser;
  }

  void fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('Cart')
          .where('clients', isEqualTo: user.uid)
          .get();
      setState(() {
        cartItems = Map.fromEntries(cartSnapshot.docs
            .map((doc) => MapEntry(doc['productId'] as String, true)));
      });
    }
  }

  void fetchWishlistItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot wishlistSnapshot = await FirebaseFirestore.instance
          .collection('Wishlist')
          .where('clients', isEqualTo: user.uid)
          .get();
      setState(() {
        wishlistItems = Map.fromEntries(wishlistSnapshot.docs
            .map((doc) => MapEntry(doc['productId'] as String, true)));
      });
    }
  }

  Widget allItems(AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Text("No items available");
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: snapshot.data!.docs.length,
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        DocumentSnapshot ds = snapshot.data!.docs[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(
                  detail: ds["detail"],
                  image: ds["image"],
                  name: ds["name"],
                  price: ds["price"].toString(),
                  productID: ds.id,
                ),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.all(4),
            child: Material(
              elevation: 5.0,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        ds["image"],
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      ds["name"],
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      "\$" + ds["price"].toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = Map<String, bool>.fromEntries(
        prefs
            .getKeys()
            .where((key) => prefs.getBool(key) ?? false)
            .map((key) => MapEntry<String, bool>(key, true)),
      );
    });
  }

  Future<void> _saveFavorite(String productId, bool isFavorite) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(productId, isFavorite);
  }

  void toggleFavorite(String productId, bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;

    // Mettre à jour l'état de isInWishlist pour refléter l'action de l'utilisateur
    setState(() {
      if (isInWishlist.containsKey(productId)) {
        isInWishlist[productId] = !isInWishlist[productId]!;
      } else {
        isInWishlist[productId] = true;
      }
    });

    if (user != null) {
      if (isFavorite) {
        FirebaseFirestore.instance.collection('Wishlist').add({
          'clients': user.uid,
          'productId': productId,
        });
      } else {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Wishlist')
            .where('clients', isEqualTo: user.uid)
            .where('productId', isEqualTo: productId)
            .get();

        querySnapshot.docs.first.reference.delete();
      }
    }

    _saveFavorite(
        productId, isFavorite); // Sauvegarder le favori dans SharedPreferences

    setState(() {
      favorites[productId] = isFavorite;
    });

    FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({'wish': isFavorite});
  }

  Widget showProductsInterese() {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<String>>(
          future: getMostSearchedProducts(_auth.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text("No products");
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (context, index) {
                String productId = snapshot.data![index];

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .snapshots(),
                  builder: (context, productSnapshot) {
                    if (!productSnapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    var productData =
                        productSnapshot.data!.data() as Map<String, dynamic>;

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('promotions')
                          .where('productId', isEqualTo: productId)
                          .get(),
                      builder: (context, promoSnapshot) {
                        double? percentage;
                        double? sellingPrice;
                        double? modifiedPrice;

                        if (promoSnapshot.connectionState ==
                                ConnectionState.done &&
                            promoSnapshot.hasData) {
                          var promoData = promoSnapshot.data!.docs.first.data()
                              as Map<String, dynamic>;

                          percentage = promoData['percentage'] as double?;
                          sellingPrice =
                              double.parse(productData['price'].toString());

                          if (percentage != null && sellingPrice != null) {
                            modifiedPrice = sellingPrice -
                                (sellingPrice * (percentage / 100));
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Details(
                                  detail: productData['detail'],
                                  image: productData['image'],
                                  name: productData['name'],
                                  price: modifiedPrice != null
                                      ? "\$$modifiedPrice"
                                      : "\$" + productData['price'].toString(),
                                  productID: productId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 215, 220, 220),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 8, 0, 0)
                                      .withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 10,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 130,
                                      width: 160,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              productData['image'] ?? ''),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Icon(
                                        Icons.favorite_border,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (percentage != null)
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: Container(
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            "${percentage.toString()}% OFF",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 10.0),
                                Text(
                                  productData['name'] ?? '',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 5.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_business_outlined,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    SizedBox(width: 5.0),
                                    Text(
                                      modifiedPrice != null
                                          ? "\$$modifiedPrice"
                                          : "\$" +
                                              productData['price'].toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (sellingPrice != null)
                                      SizedBox(width: 5.0),
                                    if (sellingPrice != null)
                                      Text(
                                        "(\$${sellingPrice.toString()})",
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        SizedBox(height: 20.0),
      ],
    );
  }

  Future<List<String>> getMostSearchedProducts(String userId) async {
    List<String> productIds = [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('historique_search')
        .where('id_client', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    for (var doc in querySnapshot.docs) {
      String? productId = doc['liste_'] as String?;
      if (productId != null && productId.isNotEmpty) {
        productIds.add(productId);
      }
    }

    return productIds;
  }
}
