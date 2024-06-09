import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // Importer le package Geolocator

class DeliveryStatus extends StatefulWidget {
  @override
  _DeliveryStatusState createState() => _DeliveryStatusState();
}

class _DeliveryStatusState extends State<DeliveryStatus> {
  late bool en_ligne;
  late bool locationPermission;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var isButtonVisible = false;

  @override
  void initState() {
    super.initState();
    en_ligne = false;
    locationPermission = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حالة التسليم'),
        actions: [], //widgets ineratifs buttons , icons , liste vide dans mon cas
      ),
      body: Center(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Cart')
              .where('id_livreur',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .where('status', whereNotIn: [
            'refused',
            'in progress',
            'en route ',
            'delivered',
            'cancelled'
          ]).snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            //contexte de la construction actuelle.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } // l'état actuel de la connexion à la source de données dans le snapshot= est en cours de chargement.

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No livraison yet.');
            }

            return ListView.builder(
              // ListView qui construit dynamiquement  POUR données asynchrones DANS FIRESTORE
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

  Future<void> _acceptInvitation(String clientId) async {
    DocumentSnapshot clientSnapshot = await FirebaseFirestore.instance
        .collection('clients')
        .doc(clientId)
        .get();

    if (!clientSnapshot.exists) {
      throw 'Client not found';
    }

    var clientData = clientSnapshot.data() as Map<String, dynamic>;
    double latitude = clientData['latitude'];
    double longitude = clientData['longitude'];

    String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
//fonction asynchrone fournie par le package url_launcher en Flutter. Elle prend une URL
//en tant que paramètre et retourne un Future booléen indiquant si l'URL peut être lancée avec succès sur le dispositif
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
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
            trailing: IconButton(
              icon: Icon(Icons.check_circle_outline,
                  color: Color.fromARGB(255, 23, 24, 23), size: 30),
              onPressed: () async {
                if (cartItem['status'] == 'confirmed') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Commencer la livraison'),
                        content: Text(
                            'Vous pouvez commencer la livraison maintenant.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () async {
                              _acceptInvitation(cartItem['clients']);
                              await FirebaseFirestore.instance
                                  .collection('Cart')
                                  .doc(cartItem.id)
                                  .update({
                                'status': 'en route',
                                'date_status': FieldValue.serverTimestamp(),
                              });

                              Navigator.of(context).pop();
                            },
                            child: Text('Commencer'),
                          ),
                        ],
                      );
                    },
                  );
                } else if (cartItem['status'] == 'prepared') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Commande  en cours de preparartion '),
                        content: Text(
                            'Cette commande n\'a pas été confirmée par l\'administrateur.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else if (cartItem['status'] == 'accepted') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('انتظر'),
                        content: Text('لم نتلقى إجابة بعد '),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
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
