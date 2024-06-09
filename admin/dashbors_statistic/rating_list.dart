import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:group_list_view/group_list_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ReviewsProduct extends StatefulWidget {
  const ReviewsProduct({super.key});

  @override
  State<ReviewsProduct> createState() => _ReviewsProductState();
}

class _ReviewsProductState extends State<ReviewsProduct> {
  late Stream<QuerySnapshot> _reviewsStream;
  late Future<List<DocumentSnapshot>> _productsFuture;
  FirebaseStorage storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _reviewsStream =
        FirebaseFirestore.instance.collection('reviews').snapshots();
    _productsFuture = FirebaseFirestore.instance
        .collection('products')
        .get()
        .then((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.teal.shade400.withOpacity(.8),
          title: const Center(
            child: Text(
              'Reviews',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.twistingDots(
                leftDotColor: const Color(0xFF1A1A3F),
                rightDotColor: const Color(0xFFEA3799),
                size: 50,
              ),
            );
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: _productsFuture,
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: LoadingAnimationWidget.twistingDots(
                    leftDotColor: const Color(0xFF1A1A3F),
                    rightDotColor: const Color(0xFFEA3799),
                    size: 50,
                  ),
                );
              }
              if (productSnapshot.hasError) {
                return Center(child: Text('Error: ${productSnapshot.error}'));
              }

              final products = productSnapshot.data!
                  .asMap()
                  .map((index, doc) => MapEntry(doc.id, doc))
                  .cast<String, DocumentSnapshot>();

              final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

              return GroupListView(
                sectionsCount: documents.length,
                countOfItemInSection: (int section) => 1,
                itemBuilder: (BuildContext context, IndexPath indexPath) {
                  var review = documents[indexPath.section];
                  String imagePath;

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

                  // Fetch product name
                  String productId = review['productID'];
                  String productName = products.containsKey(productId)
                      ? products[productId]!['name']
                      : 'Unknown Product';

                  return ExpansionTile(
                    iconColor: Colors.teal,
                    collapsedShape: const StadiumBorder(
                      side: BorderSide(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      side: const BorderSide(color: Colors.teal, width: 2.0),
                    ),
                    leading: Image.asset(imagePath),
                    title: Text(
                      "${review['userName']} ${review['userSurname']}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBarIndicator(
                          rating: review['rating']?.toDouble() ?? 0.0,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                        Text(
                          productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    children: <Widget>[
                      ListTile(
                        title: Text(
                          review['comment'] ?? 'No comments available',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                groupHeaderBuilder: (BuildContext context, int section) {
                  return const Padding(
                    padding: EdgeInsets.all(0.0),
                    child: Text(
                      "",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                },
                scrollDirection: Axis.vertical,
                reverse: false,
                primary: true,
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemExtent: null,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                addSemanticIndexes: true,
                cacheExtent: 100,
                semanticChildCount: null,
              );
            },
          );
        },
      ),
    );
  }
}
