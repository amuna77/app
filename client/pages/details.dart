import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:my_application/client/pages/full_image.dart';

class Details extends StatefulWidget {
  final String detail;
  final String image;
  final String name;
  final String price;
  final String productID;

  Details({
    required this.detail,
    required this.image,
    required this.name,
    required this.price,
    required this.productID,
  });

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  bool showReviews = false;
  int totalReviews = 0;

  int new_quantity = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool a = false;
  int quantity = 0;
  double total = 0.0;
  double productPrice = 0.0;
  List<Map<String, dynamic>> reviews = [];
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0.0;
  String defaultImage = '';
  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _loadUserDetails();
    _loadReviews();
    cleanUpCart();
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

  _loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot clientSnapshot = await FirebaseFirestore.instance
            .collection('clients')
            .doc(user.uid)
            .get();

        if (clientSnapshot.get('image') == null) {
          String userSex = clientSnapshot['gender'] ?? '';
          defaultImage =
              userSex == 'Female' ? 'assets/female.png' : 'assets/male.png';

          // Utilisez defaultImage pour afficher une image par défaut
        } else {}
      } catch (e) {
        print("Erreur lors du chargement des détails de l'utilisateur : $e");
      }
    }
  }

  _loadReviews() async {
    try {
      QuerySnapshot reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productID', isEqualTo: widget.productID)
          .get();

      setState(() {
        reviews = reviewsQuery.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        totalReviews = reviews.length;
      });
    } catch (e) {
      print("Erreur lors du chargement des avis : $e");
    }
  }

  _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text('نعم'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.price.isNotEmpty) {
      try {
        total = double.parse(widget.price);
      } catch (e) {
        debugPrint('Error parsing price: $e');
        total = 0.0;
      }
    }

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                SizedBox(height: 20.0),
                _buildProductImage(),
                SizedBox(height: 20.0),
                _buildProductName(),
                SizedBox(height: 20.0),
                _buildQuantitySelector(),
                SizedBox(height: 20.0),
                _buildProductDetails(),
                SizedBox(height: 20.0),
                _buildTotalPrice(),
                _buildAddToCartButton(),
                SizedBox(height: 20.0),
                _buildReviewsSection(),
                SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
      child: GestureDetector(
        onTap: () => _addToCart(),
        child: Container(
          width: MediaQuery.of(context).size.width / 2,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "أضف إلى السلة",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(width: 10.0),
              Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Icon(
        Icons.arrow_back_ios_new_outlined,
        color: Colors.black,
      ),
    );
  }

  Widget _buildProductImage() {
    return GestureDetector(
      onTap: () {
        // Ouvrir l'image en plein écran
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(imageUrl: widget.image),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 200.0,
        child: Image.network(
          widget.image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProductName() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Text(
        widget.name,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showQuantityErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "حدد الكمية",
              style: TextStyle(fontSize: 18.0),
            ),
            Icon(Icons.error, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Text(
      widget.detail,
      maxLines: 4,
    );
  }

  Widget _buildTotalPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '    سعر الوحدة:   ' + total.toStringAsFixed(2) + 'دج ',
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            "التعليقات",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
        ),
        _buildReviewForm(),
        SizedBox(height: 20.0),
        if (showReviews)
          SingleChildScrollView(
            child: _buildReviewsList(),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "التعليقات ($totalReviews)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showReviews = !showReviews;
                  });
                },
                child: Icon(
                  showReviews ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 30.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            setState(() {
              _rating = rating;
            });
          },
        ),
        SizedBox(height: 10.0),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "    ...إضافة تقييمك    ",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10.0),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              _postReview();
              showReviews = true;
              _buildReviewsList();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue, // Couleur du texte du bouton
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // Bord arrondi
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 15.0), // Espacement interne
            ),
            child: Text(
              "نشر",
              style: TextStyle(
                fontSize: 18.0, // Taille du texte
                fontWeight: FontWeight.bold, // Texte en gras
              ),
            ),
          ),
        )
      ],
    );
  }

  void _postReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot clientSnapshot = await FirebaseFirestore.instance
            .collection('clients')
            .doc(user.uid)
            .get();

        String userImage = '';
        if (clientSnapshot.exists && clientSnapshot.data() != null) {
          final userData = clientSnapshot.data() as Map<String, dynamic>;

          // Assume que userData est une Map<String, dynamic> contenant les données de l'utilisateur

          if (userData['image'] != null && userData['image'].isNotEmpty) {
            // Utiliser l'image de l'utilisateur si elle est définie
            userImage = userData['image'];
          }

          await FirebaseFirestore.instance.collection('reviews').add({
            'productID': widget.productID,
            'userID': user.uid,
            'userName': clientSnapshot['surname'],
            'userSurname': clientSnapshot['name'],
            'userImage': userImage,
            'rating': _rating,
            'comment': _commentController.text,
            'timestamp': Timestamp.now(),
            'userGender': clientSnapshot['gender'],
          });
        }

        _commentController.clear();
        setState(() {
          _rating = 0.0;
        });

        _loadReviews();
      } catch (e) {
        print("Error posting review: $e");
      }
    }
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        var review = reviews[index];
        String imagePath;
        // Determine the image path based on gender or use a default if no image is provided
        if (review['userImage'] != null) {
          // Use Firebase Storage URL if available
          imagePath = review['userImage'];
        } else {
          String userGender = review['userGender'];

          if (userGender == 'Female') {
            imagePath = 'assets/female.png';
          } else {
            imagePath = 'assets/male.png';
          }
        }

        return ListTile(
          leading: CircleAvatar(
            // Use NetworkImage to load image from URL
            backgroundImage: NetworkImage(imagePath),
          ),
          title: Text(
            "${review['userName']} ${review['userSurname']}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingBarIndicator(
                rating: review['rating']?.toDouble() ?? 0.0,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 20.0,
                direction: Axis.horizontal,
              ),
              SizedBox(height: 5.0),
              Text(review['comment'] ?? ''),
            ],
          ),
        );
      },
    );
  }

  double calculateTotalPrice(int quantity, double productPrice) {
    return quantity * productPrice;
  }

  Future<String> getOrCreateCart(String userId) async {
    try {
      QuerySnapshot cartQuery = await FirebaseFirestore.instance
          .collection('Cart')
          .where('clients', isEqualTo: userId)
          .where('checkout', isEqualTo: false)
          .get();

      if (cartQuery.docs.isNotEmpty) {
        return cartQuery.docs.first.id;
      } else {
        DocumentReference cartRef =
            await FirebaseFirestore.instance.collection('Cart').add({
          'clients': userId,
          'created_at': FieldValue.serverTimestamp(),
          'checkout': false,
          'total_price': 0.0
        });
        return cartRef.id;
      }
    } catch (e) {
      print("Erreur lors de la récupération ou la création du panier : $e");
      throw e;
    }
  }

  Future<void> add(String cartId, String productId, int quantity) async {
    try {
      QuerySnapshot existingDetails = await FirebaseFirestore.instance
          .collection('details')
          .where('id_cart', isEqualTo: cartId)
          .where('id_produit', isEqualTo: productId)
          .get();

      QuerySnapshot details = await FirebaseFirestore.instance
          .collection('details')
          .where('id_cart', isEqualTo: cartId)
          .get();

      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      QuerySnapshot promotionSnapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('productId', isEqualTo: productId)
          .get();

      double unitPrice;
      if (promotionSnapshot.docs.isNotEmpty) {
        DocumentSnapshot promotionDoc = promotionSnapshot.docs.first;
        unitPrice = promotionDoc['discountedPrice'];
      } else {
        unitPrice = productDoc['price'];
      }
      double totalPrice = quantity * unitPrice;
      print(totalPrice);
      if (!productDoc.exists) {
        throw Exception("Product not found");
      }

      if (existingDetails.docs.isNotEmpty) {
        DocumentSnapshot detailDoc = existingDetails.docs.first;
        int currentQuantity = detailDoc['quantite'] ?? 0;

        if (currentQuantity == quantity) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("المنتج موجود بالفعل في سلة التسوق"),
                content: Text("هل تريد إضافة هذه الكمية إلى الكمية السابقة؟"),
                actions: <Widget>[
                  TextButton(
                    child: Text("Yes"),
                    onPressed: () async {
                      // Add the quantity to the current quantity in the database
                      detailDoc = details.docs.first;
                      double total_price = detailDoc['total_price'] ?? 0.0;

                      DocumentSnapshot<Map<String, dynamic>> cartDocument =
                          await FirebaseFirestore.instance
                              .collection('Cart')
                              .doc(cartId)
                              .get();

                      if (cartDocument.exists) {
                        double ancien_total =
                            cartDocument.data()!['total_price'] ?? 0.0;
                        await cartDocument.reference.update({
                          'total_price': ancien_total + total_price,
                        });
                      }
                      // Here you should put your database update logic
                      // For example:
                      // updateQuantityInDatabase(newQuantity);

                      // Close the dialog
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text("لا"),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              );
            },
          );
          return;
        } else {
          await FirebaseFirestore.instance
              .collection('details')
              .where('id_produit', isEqualTo: widget.productID)
              .get()
              .then((querySnapshot) async {
            for (DocumentSnapshot document in querySnapshot.docs) {
              int currentQuantite = document['quantite'];
              double unit_price = document['unit_price'];

              double total_price = unit_price * (currentQuantite + quantity);
              document.reference.update({
                'quantite': currentQuantite + quantity,
                'total_price': total_price,
              });

              await FirebaseFirestore.instance
                  .collection('Cart')
                  .doc(cartId)
                  .get()
                  .then((querySnapshot) {
                DocumentSnapshot<Map<String, dynamic>> document = querySnapshot;
                double ancien_total = document['total_price'];
                document.reference.update({
                  'total_price': ancien_total + total_price,
                });
              }).catchError((error) {
                print("Error updating quantite: $error");
              });
            }
          }).catchError((error) {
            print("Error updating quantite: $error");
          });
        }
      } else if (details.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection('details').add({
          'id_cart': cartId,
          'id_produit': productId,
          'quantite': quantity,
          'created_at': FieldValue.serverTimestamp(),
          'unit_price': unitPrice,
          'total_price': totalPrice,
        });

        DocumentSnapshot<Map<String, dynamic>> cartDocument =
            await FirebaseFirestore.instance
                .collection('Cart')
                .doc(cartId)
                .get();

        if (cartDocument.exists) {
          double ancien_total = cartDocument.data()!['total_price'] ?? 0.0;
          double new_total = ancien_total + totalPrice;
          await cartDocument.reference.update({
            'total_price': new_total,
          });
        }
      } else {
        await FirebaseFirestore.instance.collection('details').add({
          'id_cart': cartId,
          'id_produit': productId,
          'quantite': quantity,
          'created_at': FieldValue.serverTimestamp(),
          'unit_price': unitPrice,
          'total_price': totalPrice,
        });
        DocumentSnapshot<Map<String, dynamic>> existingCart =
            await FirebaseFirestore.instance
                .collection('Cart')
                .doc(cartId)
                .get();

        // Vérifier si le document existe
        if (existingCart.exists) {
          await FirebaseFirestore.instance
              .collection('Cart')
              .doc(cartId)
              .update({
            'total_price': totalPrice,
          });
        }
      }
    } catch (e) {
      print("Erreur lors de l'ajout des détails : $e");
      throw e;
    }
  }

  void _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        if (quantity == 0)
          _showQuantityErrorSnackBar();
        else {
          DocumentSnapshot product = await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productID)
              .get();

          if (product.exists) {
            int currentQuantity = product['quantity'];
            int secureQuantity = product['secureQuantity'];
            int temp = currentQuantity - quantity;
            if (temp < secureQuantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Color.fromARGB(255, 155, 45, 45),
                  content: Text(
                    "إنتهى من المخزن ",
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              );
            } else {
              DocumentSnapshot<Map<String, dynamic>> product =
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(widget.productID)
                      .get();
              int current_quantite = product['quantity'];
              // Check if the product exists
              if (product.exists) {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.productID)
                    .update({
                  'quantity': current_quantite - quantity,
                });

                String cartId = await getOrCreateCart(user.uid);

                add(cartId, widget.productID, quantity);

                print(new_quantity);
                print(quantity);
                // Affiche un message indiquant que le produit a été ajouté au panier
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Color.fromARGB(255, 64, 255, 163),
                    content: Text(
                      "تم إضافة المنتج إلى سلة التسوق",
                      style: TextStyle(fontSize: 18.0),
                    ),
                    duration: Duration(
                        seconds:
                            5), // Durée personnalisée, par exemple 5 secondes
                  ),
                );

                await calculateAndUpdateCartTotalPrice(cartId);
              }
            }
          }
          // Calcule et met à jour le prix total du panier
        }
      } catch (e) {
        _showErrorDialog("خطأ", "حدث خطأ أثناء الإضافة إلى السلة.");
        print("Erreur lors de l'ajout au panier : $e");
      }
    }
  }

// Dans la fonction calculateAndUpdateCartTotalPrice()

  Future<void> calculateAndUpdateCartTotalPrice(String cartId) async {
    try {
      QuerySnapshot cartDetailsQuery = await FirebaseFirestore.instance
          .collection('details')
          .where('id_cart', isEqualTo: cartId)
          .get();

      double totalPrice = 0.0;

      for (QueryDocumentSnapshot detailSnapshot in cartDetailsQuery.docs) {
        String productId = detailSnapshot['id_produit'];
        int quantity = detailSnapshot['quantite'];

        DocumentSnapshot productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          double productPrice = (productDoc['price'] ?? 0.0) as double;
          totalPrice += productPrice * quantity;
        }
      }

      // Mettre à jour le document Cart avec le nouveau prix total
      await updateCartTotalPrice(cartId, totalPrice);
    } catch (e) {
      print("Erreur lors du calcul et de la mise à jour du total_price : $e");
      throw e;
    }
  }

// Dans la fonction updateCartTotalPrice()

  Future<void> updateCartTotalPrice(String cartId, double totalPrice) async {
    try {
      await FirebaseFirestore.instance.collection('Cart').doc(cartId).update({
        'total_price': totalPrice,
      });
    } catch (e) {
      print("Erreur lors de la mise à jour du total_price : $e");
      throw e;
    }
  }

  _loadProductDetails() async {
    try {
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productID)
          .get();

      if (productDoc.exists) {
        productPrice = (productDoc['price'] ?? 0.0) as double;

        // Initialise quantity à 0 ici
        quantity = 0;

        // Fetch quantity from the ligne_facture collection
        QuerySnapshot ligneFactureQuery = await FirebaseFirestore.instance
            .collection('detailProduct')
            .where('productId', isEqualTo: widget.productID)
            .get();

        if (ligneFactureQuery.docs.isNotEmpty) {
          // Commenting out the following lines will ensure quantity remains 0
          // quantity = ligneFactureQuery.docs.first['quantity'] ?? 0;
        }

        setState(() {
          total = productPrice * quantity;
        });
      }
    } catch (e) {
      _showErrorDialog("خطأ", "لم يتم العثور على المنتج. اقرأ المزيد.");
      print("Erreur lors du chargement des détails du produit : $e");
    }
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        _buildQuantityButton(Icons.remove, () async {
          if (quantity > 0) {
            setState(() {
              quantity--;
            });

            try {
              DocumentSnapshot product = await FirebaseFirestore.instance
                  .collection('products')
                  .doc(widget.productID)
                  .get();

              if (product.exists) {
                int currentQuantity = product['quantity'];
                new_quantity = currentQuantity + quantity;

                // Update the product quantity in Firestore if needed
              }
            } catch (e) {
              print("Error updating quantity: $e");
            }
          }
        }),
        SizedBox(width: 20.0),
        Text(
          '$quantity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 20.0),
        _buildQuantityButton(Icons.add, () async {
          setState(() {
            quantity++;
          });
          try {
            DocumentSnapshot product = await FirebaseFirestore.instance
                .collection('products')
                .doc(widget.productID)
                .get();

            if (product.exists) {
              int currentQuantity = product['quantity'];
              int secureQuantity = product['secureQuantity'];
              int temp = currentQuantity - quantity;
              if (temp > secureQuantity) {
                new_quantity = currentQuantity - quantity;

                // Update the product quantity in Firestore if needed
              } else {
                // Show an error dialog

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('إنتهى من المخزن'),
                      content: Text('الكمية الآن غير  متوفرة '),
                      actions: <Widget>[
                        TextButton(
                          child: Text('نعم'),
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
          } catch (e) {
            print("Error updating quantity: $e");
          }
        }),
      ],
    );
  }
}
