import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeLivreur extends StatefulWidget {
  @override
  _HomeLivreurState createState() => _HomeLivreurState();
}

class _HomeLivreurState extends State<HomeLivreur> {
  bool en_ligne = false;
  bool locationPermission = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات '),
        actions: [],
      ),
      body: Center(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Cart')
              .where('id_livreur',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .where('status', isEqualTo: 'in progress')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text("لا توجد طلبات بعد.");
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var cartItem = snapshot.data!.docs[index];
                return _buildInvitationCard(cartItem);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInvitationCard(DocumentSnapshot cartItem) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('clients')
          .doc(cartItem['clients'])
          .get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> clientSnapshot) {
        if (clientSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (!clientSnapshot.hasData || !clientSnapshot.data!.exists) {
          return Text(
            'Client not found',
            style: TextStyle(color: Colors.red),
          );
        }

        var clientData = clientSnapshot.data!.data() as Map<String, dynamic>;

        return Card(
          elevation: 3,
          margin: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(15),
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(clientData['image'] ?? ''),
            ),
            title: Text(
              '${clientData['name']} ${clientData['surname']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رقم الهاتف ${clientData['phoneNumber']}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 5),
                InkWell(
                  onTap: () async {
                    String googleMapsUrl =
                        'https://www.google.com/maps/search/?api=1&query=${clientData['latitude']},${clientData['longitude']}';
                    if (await canLaunch(googleMapsUrl)) {
                      await launch(googleMapsUrl);
                    } else {
                      throw 'Could not launch $googleMapsUrl';
                    }
                  },
                  child: Text(
                    'عنوان',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                InkWell(
                  onTap: () {
                    _showOrderDetails(cartItem['clients']);
                  },
                  child: Text(
                    'تفاصيل الطلب',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle,
                      color: Color.fromARGB(255, 23, 24, 23), size: 30),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('Cart')
                        .doc(cartItem.id)
                        .update({
                      'status': 'accepted',
                      'date_status': FieldValue.serverTimestamp(),
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.cancel,
                      color: const Color.fromARGB(255, 11, 11, 11), size: 30),
                  onPressed: () {
                    _rejectInvitation(cartItem.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rejectInvitation(String cartItemId) async {
    // Write your logic to reject the invitation here
    await FirebaseFirestore.instance.collection('Cart').doc(cartItemId).update({
      'status': 'refused',
      'date_status': FieldValue.serverTimestamp(),
    });
  }

  void _showOrderDetails(String clientId) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('Cart')
              .where('clients', isEqualTo: clientId)
              .get(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('No order details available.'),
              );
            }

            var cartDoc = snapshot.data!.docs.first;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                padding: EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('details')
                            .where('id_cart', isEqualTo: cartDoc.id)
                            .get(),
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text('No order details available.'),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: snapshot.data!.docs.map((detail) {
                              return FutureBuilder(
                                future: FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(detail['id_produit'])
                                    .get(),
                                builder: (context,
                                    AsyncSnapshot<DocumentSnapshot>
                                        productSnapshot) {
                                  if (productSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (!productSnapshot.hasData ||
                                      !productSnapshot.data!.exists) {
                                    return Text('Product not found');
                                  }

                                  var productData = productSnapshot.data!.data()
                                      as Map<String, dynamic>;

                                  return Card(
                                    elevation: 2.0,
                                    margin:
                                        EdgeInsets.symmetric(vertical: 10.0),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(10.0),
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.network(
                                          '${productData['image']}',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${productData['name']}',
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 5.0),
                                          Text(
                                            '${productData['brand']}',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${detail['quantite']}',
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                      trailing: Text(
                                        '${detail['unit_price'] ?? 'N/A'} DA',
                                        style: TextStyle(fontSize: 16.0),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
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
      },
    );
  }
}
