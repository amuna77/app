import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_application/client/pages/bottomnav.dart';
import 'package:my_application/client/pages/checkout.dart';

class NotificationPage extends StatelessWidget {
  static final List<String> notifiedDocuments = [];

  @override
  Widget build(BuildContext context) {
    notifierClient(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: Center(
        child: Text(
          notifiedDocuments.isEmpty ? 'No notifications' : '',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void notifierClient(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await checkCartDocumentConditions(context, user.uid);
    }
  }

  Future<void> checkCartDocumentConditions(
      BuildContext context, String userId) async {
    final QuerySnapshot acceptedResult = await FirebaseFirestore.instance
        .collection('Cart')
        .where('clients', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (acceptedResult.docs.isNotEmpty) {
      await handleCartDocuments(context, acceptedResult, 'accepted');
    }

    final QuerySnapshot refusedResult = await FirebaseFirestore.instance
        .collection('Cart')
        .where('clients', isEqualTo: userId)
        .where('status', isEqualTo: 'refused')
        .get();

    if (refusedResult.docs.isNotEmpty) {
      await handleCartDocuments(context, refusedResult, 'refused');
    }
  }

  Future<void> handleCartDocuments(
      BuildContext context, QuerySnapshot result, String status) async {
    for (final doc in result.docs) {
      if (notifiedDocuments.contains(doc.id)) continue;

      String livreurId = doc['id_livreur'];

      if (livreurId.isNotEmpty) {
        final DocumentSnapshot livreurDoc = await FirebaseFirestore.instance
            .collection('livreurs')
            .doc(livreurId)
            .get();

        if (livreurDoc.exists) {
          final Map<String, dynamic> data =
              livreurDoc.data() as Map<String, dynamic>;
          final String name = data['name'];
          final String surname = data['surname'];

          if (status == 'accepted') {
            buildNotification(
                context,
                name,
                surname,
                'La commande est prête !',
                'Le livreur $name $surname est en route.',
                Colors.green,
                status);
          } else if (status == 'refused') {
            buildNotification(
                context,
                name,
                surname,
                'Invitation refusée',
                'Le livreur $name $surname a refusé la commande.',
                Colors.red,
                status);
          }

          notifiedDocuments.add(doc.id);

          await checkDeliveryConditions(context, doc['clients'], livreurId);
        }
      }
    }
  }

  void buildNotification(BuildContext context, String name, String surname,
      String title, String message, Color color, String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        size: 40,
                        color: color,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nouvelle Notification',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (status == 'accepted') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNav()),
                          );
                        } else if (status == 'refused') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CheckoutScreen()),
                          );
                        }
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> searchLivreurById(BuildContext context, String clientId) async {
    final QuerySnapshot cartResult = await FirebaseFirestore.instance
        .collection('Cart')
        .where('clients', isEqualTo: clientId)
        .where('status', isEqualTo: 'accepted')
        .get();

    for (final cartDoc in cartResult.docs) {
      String livreurId = cartDoc['id_livreur'];

      final DocumentSnapshot livreurSnapshot = await FirebaseFirestore.instance
          .collection('livreurs')
          .doc(livreurId)
          .get();

      print('Livreur: ${livreurSnapshot.data()}');
    }
  }

  Future<void> checkDeliveryConditions(
      BuildContext context, String clientId, String livreurId) async {
    final DocumentSnapshot clientSnapshot = await FirebaseFirestore.instance
        .collection('clients')
        .doc(clientId)
        .get();

    final DocumentSnapshot livreurSnapshot = await FirebaseFirestore.instance
        .collection('livreurs')
        .doc(livreurId)
        .get();

    final Map<String, dynamic>? clientData =
        clientSnapshot.data() as Map<String, dynamic>?;
    final Map<String, dynamic>? livreurData =
        livreurSnapshot.data() as Map<String, dynamic>?;

    if (clientData != null && livreurData != null) {
      final double clientLatitude = clientData['latitude'];
      final double clientLongitude = clientData['longitude'];
      final double livreurLatitude = livreurData['latitude'];
      final double livreurLongitude = livreurData['longitude'];

      // Vérifiez si les coordonnées sont proches
      if (clientLatitude == livreurLatitude &&
          clientLongitude == livreurLongitude) {
        // Afficher la notification
        buildNotification(
          context,
          '',
          '',
          'Votre commande est livrée !',
          'Votre commande a été livrée avec succès.',
          Colors.blue,
          'delivered',
        );

        // Mise à jour du statut dans la collection 'Cart'
        final QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
            .collection('Cart')
            .where('clients', isEqualTo: clientId)
            .where('id_livreur', isEqualTo: livreurId)
            .where('status', isEqualTo: 'en route')
            .get();

        cartSnapshot.docs.forEach((doc) {
          doc.reference.update({
            'status': 'delivered',
            'date_status': FieldValue.serverTimestamp(),
          });
        });
      }
    }
  }
}
