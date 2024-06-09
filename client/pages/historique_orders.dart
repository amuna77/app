import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Orders extends StatefulWidget {
  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final User? user = FirebaseAuth.instance.currentUser;
  int? selectedCardIndex;

  Future<Map<String, dynamic>?> getLivreurInfo(String id) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('livreurs').doc(id).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching livreur info: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تاريخ الطلبات  '),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Cart')
            .where('clients', isEqualTo: user!.uid)
            .where('checkout', isEqualTo: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'لا توجد طلبات حتى الآن.',
                style: TextStyle(fontSize: 16),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ أثناء جلب البيانات.',
                style: TextStyle(fontSize: 16),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var cart =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                bool isSelected = selectedCardIndex == index;

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: isSelected ? Colors.black : Colors.white,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedCardIndex = index;
                      });
                      // Naviguer vers les détails de la commande
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartDetailsScreen(
                              cartId: snapshot.data!.docs[index].id),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.shopping_bag,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      title: Text(
                        ' ألطلبية ',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ' ${cart['created_at']?.toDate()}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            ' ${cart['status']} :حالة طلبية  ',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'دج  ${cart['total_price'] ?? ''}   : الثمن الإجملي',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            cart.containsKey('percentage')
                                ? ' ${cart['percentage']} %     : مخصومة بنسبة مئوية:'
                                : '',
                            style: TextStyle(
                              color: Color.fromARGB(255, 202, 194, 188),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FutureBuilder<Map<String, dynamic>?>(
                            future: getLivreurInfo(cart['id_livreur'] ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(
                                  '...جارٍ تحميل معلومات موظف التوصيل',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                );
                              }
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data == null) {
                                return Text(
                                  'موظف توصيل  غير المختار',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                );
                              }

                              var livreurData = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '   ${livreurData['name'] ?? ''} ${livreurData['surname'] ?? ''}رجل   التسليم    ',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '  ${livreurData['phoneNumber'] ?? ''}  الهاتف',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class CartDetailsScreen extends StatelessWidget {
  final String cartId;

  CartDetailsScreen({required this.cartId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('details')
            .where('id_cart', isEqualTo: cartId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator()); // Afficher l'indicateur de chargement
          }

          if (!snapshot.hasData) {
            return Center(
                child: Text(
                    'لا تتوافر بيانات')); // Afficher un message s'il n'y a pas de données disponibles
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var detail =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 25,
                margin: EdgeInsets.symmetric(vertical: 24, horizontal: 30),
                color: Color.fromARGB(255, 215, 219, 198),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('products')
                            .doc(detail['id_produit'].toString())
                            .get(),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                          if (productSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              width: 120,
                              height: 120,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!productSnapshot.hasData) {
                            return SizedBox(
                              width: 120,
                              height: 120,
                              child: Center(
                                child: Text('      منتج   غير متوفر'),
                              ),
                            );
                          }

                          var product = productSnapshot.data!.data()
                              as Map<String, dynamic>;

                          return Stack(
                            children: [
                              Image.network(
                                product['image'] ??
                                    'https://via.placeholder.com/150',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                              if (productSnapshot.connectionState ==
                                  ConnectionState.waiting)
                                Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder(
                              future: FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(detail['id_produit'].toString())
                                  .get(),
                              builder: (context,
                                  AsyncSnapshot<DocumentSnapshot>
                                      productSnapshot) {
                                if (productSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                if (!productSnapshot.hasData) {
                                  return Text('  منتج   غير متوفر');
                                }

                                var product = productSnapshot.data!.data()
                                    as Map<String, dynamic>;

                                return Text(
                                  product['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Quantité: ${detail['quantite'] ?? ''}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Prix: ${detail['unit_price'] ?? ''} DA',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
      ),
    );
  }
}
