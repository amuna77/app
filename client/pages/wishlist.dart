import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_application/client/pages/bottomnav.dart';
import 'package:my_application/client/pages/details.dart';

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _controller;
  Map<String, bool> wishlistItems = {};
  @override
  void initState() {
    super.initState();
    fetchWishlistItems();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
      reverseDuration: Duration(milliseconds: 300),
    );
  }

  Future<void> clearAll() async {
    var wishlistSnapshot = await FirebaseFirestore.instance
        .collection('Wishlist')
        .where('clients', isEqualTo: _auth.currentUser?.uid)
        .get();

    for (var wishlistItem in wishlistSnapshot.docs) {
      await wishlistItem.reference.delete();
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
      child: Card(
        elevation: 5,
        color: Color.fromARGB(255, 217, 220, 220),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  child: Image.network(
                    image,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
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
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  if (discountedPrice != 0)
                    Text(
                      '${discountedPrice.toStringAsFixed(2)} DA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 28, 107, 30),
                        fontSize: 16,
                      ),
                    ),
                  if (sellingPrice != 0)
                    RichText(
                      text: TextSpan(
                        text: '${sellingPrice.toStringAsFixed(2)} DA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 195, 52, 41),
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  if (discountedPrice == 0 && sellingPrice == 0)
                    Text(
                      '$price DA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 68, 133, 48),
                        fontSize: 16,
                      ),
                    ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: const Color.fromARGB(255, 169, 40, 31)),
              onPressed: () {
                toggleFavorite(
                  productId,
                  !wishlistItems.containsKey(productId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget showWishlistProducts() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Wishlist')
                  .where('clients',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'قائمة المفضلة فارغة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                        fontFamily: 'Pacifico',
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data!.docs.map((doc) {
                    var productId = doc['productId'];
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

                        double price =
                            double.parse(productData['price'].toString());

                        // Vérifier si le produit est dans la collection "promotions"
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('promotions')
                              .where('productId', isEqualTo: productId)
                              .snapshots(),
                          builder: (context, promoSnapshot) {
                            if (!promoSnapshot.hasData ||
                                promoSnapshot.data!.docs.isEmpty) {
                              // Si aucun document ne correspond au filtre, afficher le produit de base
                              return buildProductCard(
                                name: productData['name'],
                                price: price.toString(),
                                image: productData['image'],
                                productId: productId,
                                detail: productData['detail'] ?? '',
                              );
                            } else {
                              // Si un document correspond au filtre, utiliser ses données de promotion
                              var promoData = promoSnapshot.data!.docs.first
                                  .data() as Map<String, dynamic>;

                              double discountedPrice =
                                  promoData['discountedPrice'] as double;
                              double percentage =
                                  promoData['percentage'] as double;
                              double sellingPrice =
                                  promoData['sellingPrice'] as double;

                              return buildProductCard(
                                name: productData['name'],
                                price: price.toString(),
                                image: productData['image'],
                                productId: productId,
                                detail: productData['detail'] ?? '',
                                sellingPrice: sellingPrice,
                                percentage: percentage,
                                discountedPrice: discountedPrice,
                              );
                            }
                          },
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Text(
          'المفضلة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 77, 75, 75),
            fontSize: 28,
            letterSpacing: 1.2,
            fontFamily: 'Pacifico',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.clear, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'مسح المفضلة',
                    style: TextStyle(color: Colors.black),
                  ),
                  content: Text(
                    'هل أنت متأكد أنك تريد مسح قائمة المفضلة؟',
                    style: TextStyle(color: Colors.black),
                  ),
                  actions: [
                    TextButton(
                      child: Text('إلغاء', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text('مسح', style: TextStyle(color: Colors.green)),
                      onPressed: () {
                        clearAll();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: showWishlistProducts(),
    );
  }
}
