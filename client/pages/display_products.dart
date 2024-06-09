import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_application/client/pages/details.dart';

class Products extends StatefulWidget {
  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  late TextEditingController _searchController;
  Map<String, bool> wishlistItems = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    fetchWishlistItems();
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

  void toggleFavorite(String productId, bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      wishlistItems[productId] = isFavorite;
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

        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.first.reference.delete();
        }
      }
    }

    FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({'wish': isFavorite});

    // Rafraîchir la liste de souhaits après la bascule
    fetchWishlistItems();
  }

  Future<List<String>> getProductsByCondition() async {
    final today = DateTime.now();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    QuerySnapshot snapshot = await _firestore.collection('detailProduct').get();
    List<DocumentSnapshot> documents = snapshot.docs;

    documents.sort((a, b) {
      DateTime aExpDate = (a['expirationDate'] as Timestamp).toDate();
      DateTime bExpDate = (b['expirationDate'] as Timestamp).toDate();
      DateTime aPurchaseDate = (a['purchaseDate'] as Timestamp).toDate();
      DateTime bPurchaseDate = (b['purchaseDate'] as Timestamp).toDate();

      int differenceA = aExpDate.difference(today).inDays;
      int differenceB = bExpDate.difference(today).inDays;

      if (differenceA == differenceB) {
        return bPurchaseDate.compareTo(aPurchaseDate);
      }

      return differenceA.compareTo(differenceB);
    });

    Set<String> uniqueProductIds = {};

    for (var doc in documents) {
      uniqueProductIds.add(doc['productId'] as String);
    }

    return uniqueProductIds.toList();
  }

  Widget showProducts() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<String>>(
              future: getProductsByCondition(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text("لا توجد منتجات");
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
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
                            return Center(child: CircularProgressIndicator());
                          }

                          var productData = productSnapshot.data!.data()
                              as Map<String, dynamic>;

                          // Vérifier si le produit est dans la collection "promotions"
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('promotions')
                                .where('productId',
                                    isEqualTo:
                                        productId) // Filtrer par l'ID du produit
                                .snapshots(),
                            builder: (context, promoSnapshot) {
                              if (!promoSnapshot.hasData ||
                                  promoSnapshot.data!.docs.isEmpty) {
                                // Si aucun document ne correspond au filtre, afficher le produit de base
                                return buildProductCard(
                                  name: productData['name'],
                                  price: productData['price'].toString(),
                                  image: productData['image'],
                                  productId: productId,
                                  detail: productData['detail'],
                                );
                              } else {
                                // Si un document correspond au filtre, utiliser ses données de promotion
                                var promoData = promoSnapshot.data!.docs.first
                                        .data()
                                    as Map<String,
                                        dynamic>; // Utilisez .docs.first pour obtenir le premier document
                                double discountedPrice =
                                    promoData['discountedPrice'] as double;
                                double percentage =
                                    promoData['percentage'] as double;

                                double sellingPrice =
                                    promoData['sellingPrice'] as double;

                                return buildProductCard(
                                  name: productData['name'],
                                  price: productData['price'].toString(),
                                  image: productData['image'],
                                  detail: productData['detail'],
                                  productId: productId,
                                  sellingPrice: sellingPrice,
                                  percentage: percentage,
                                  discountedPrice: discountedPrice,
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Widget buildProductCard({
    required String name,
    required String price,
    required String image,
    required String productId,
    required String detail,
    double discountedPrice = 0.0,
    double percentage = 0.0,
    double sellingPrice = 0.0,
  }) {
    bool isInWishlist = wishlistItems.containsKey(productId)
        ? wishlistItems[productId]!
        : false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(
              detail: detail,
              image: image,
              name: name,
              price: discountedPrice != 0 ? '$discountedPrice' : price,
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
              children: [
                Container(
                  height: 103,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (percentage != 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        '${percentage.toString()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 5, // Ajuster la position verticale
                  left: 5, // Ajuster la position horizontale
                  child: GestureDetector(
                    onTap: () {
                      toggleFavorite(
                        productId,
                        !isInWishlist,
                      ); // Inverse l'état actuel du favori
                    },
                    child: Container(
                      padding:
                          EdgeInsets.all(3), // Ajuster la taille du conteneur
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isInWishlist
                            ? Colors.red.withOpacity(0.7)
                            : Colors.white.withOpacity(0.7),
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Colors.white : Colors.grey,
                        size: 16, // Ajuster la taille de l'icône
                      ),
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
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  if (discountedPrice != 0)
                    Text(
                      '${discountedPrice.toStringAsFixed(2)} DA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 18,
                      ),
                    ),
                  if (sellingPrice != 0)
                    RichText(
                      text: TextSpan(
                        text: '${sellingPrice.toStringAsFixed(2)} DA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 18,
                          decoration: TextDecoration
                              .lineThrough, // Ajout de la décoration de texte barré
                        ),
                      ),
                    ),
                  if (discountedPrice == 0 && sellingPrice == 0)
                    Text(
                      '$price DA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 133, 212, 108),
                        fontSize: 18,
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

  @override
  Widget build(BuildContext context) {
    return showProducts();
  }
}
