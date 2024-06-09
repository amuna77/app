import 'dart:math';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_application/client/pages/bottomnav.dart';
import 'package:my_application/client/pages/mapdeslivreurs.dart';
import 'package:my_application/client/pages/order.dart';
import 'package:my_application/client/pages/settings/presentation/settings/settings.dart';
import 'package:my_application/client/pages/wishlist.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  LocationData? _locationData;
  String? _errorMsg;
  int? _selectedIndex = 1; // L'index de l'élément sélectionné par défaut

  final Location _location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSkeepSelected = false;
  String? _nearestDeliveryPersonName;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  _requestPermission() async {
    var status = await _location.requestPermission();
    if (status == PermissionStatus.granted) {
      await _saveLocation();
    } else {
      setState(() {
        _errorMsg = 'تم رفض إذن الوصول إلى الموقع';
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(_errorMsg ?? 'تم رفض إذن الوصول إلى الموقع'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Ajout d'un retour en arrière
              },
              child: Text('نعم'),
            ),
          ],
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => BottomNav()), // Ouvrir BottomNav
      );
    }
  }

  _checkLocationStatus() async {
    var status = await _location.hasPermission();
    if (status == PermissionStatus.denied) {
      await _requestPermission();
    } else if (status == PermissionStatus.granted) {
      await _saveLocation();
    } else {
      _showLocationDialog();
    }
  }

  _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('قم بتشغيل موقع الجهاز'),
        content: Text('يرجى تشغيل موقع جهازك للمتابعة'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CartScreen()), // Replace with your CartScreen widget
              );
            },
            child: Text('ًلا شكرا'),
          ),
          TextButton(
            onPressed: () {
              _requestPermission();
              Navigator.of(context).pop();
            },
            child: Text('نعم'),
          ),
        ],
      ),
    );
  }

  _saveLocation() async {
    try {
      var locationData = await _location.getLocation();
      if (locationData == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CartScreen()),
        );
        return;
      }
      setState(() {
        _locationData = locationData;
      });

      User? user = _auth.currentUser;
      if (user != null) {
        double latitude = _locationData!.latitude!;
        double longitude = _locationData!.longitude!;

        // Récupérer les anciens attributs du client
        DocumentSnapshot clientSnapshot =
            await _firestore.collection('clients').doc(user.uid).get();
        Map<String, dynamic> clientData =
            clientSnapshot.data() as Map<String, dynamic>;
        if (clientData != null) {
          // Ajouter ou mettre à jour les nouvelles coordonnées de latitude et de longitude
          clientData['latitude'] = latitude;
          clientData['longitude'] = longitude;
          clientData['timestamp'] = FieldValue.serverTimestamp();

          // Mettre à jour le document du client avec les nouveaux attributs
          await _firestore.collection('clients').doc(user.uid).set(clientData);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('خطأ'),
              content: Text('لم يتم العثور على بيانات العميل'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Ajout d'un retour en arrière
                  },
                  child: Text('نعم'),
                ),
              ],
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('خطأ'),
            content: Text('لم تتم مصادقة المستخدم"'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Ajout d'un retour en arrière
                },
                child: Text('نعم'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('خطأ'),
          content: Text("فشل في حفظ الموقع"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Ajout d'un retour en arrière
              },
              child: Text('نعم'),
            ),
          ],
        ),
      );
      print(error);
    }
  }

  _selectSkeep() async {
    User? user = _auth.currentUser;
    if (user != null && _locationData != null) {
      double clientLatitude = _locationData!.latitude!;
      double clientLongitude = _locationData!.longitude!;

      QuerySnapshot querySnapshot = await _firestore
          .collection('livreurs')
          .where('en_ligne', isEqualTo: true)
          .get();

      double? minDistance;
      String? nearestId;

      for (var doc in querySnapshot.docs) {
        double deliveryLatitude = doc['latitude'];
        double deliveryLongitude = doc['longitude'];

        double distance = _calculateDistance(clientLatitude, clientLongitude,
            deliveryLatitude, deliveryLongitude);

        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          nearestId = doc.id; // Enregistre l'ID du livreur
        }
      }

      if (nearestId != null) {
        setState(() {
          _isSkeepSelected = true;
        });

        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final QuerySnapshot result = await FirebaseFirestore.instance
              .collection('Cart')
              .where('clients', isEqualTo: user.uid)
              .where('checkout', isEqualTo: false)
              .limit(1)
              .get();
          final List<DocumentSnapshot> documents = result.docs;

          if (documents.isNotEmpty) {
            // Update the existing document
            await FirebaseFirestore.instance
                .collection('Cart')
                .doc(documents.first.id)
                .update({
              'id_livreur': nearestId,
              'status': 'in progress',
            });

            updateCheckoutStatus();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('   ...تم اختيار رجل التسليم ')),
            );
          }
        }
      }
    }
  }

  Future<void> updateCheckoutStatus() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Cart')
          .where('clients',
              isEqualTo:
                  _auth.currentUser?.uid) // Remplacez par l'ID du client actuel
          .where('checkout', isEqualTo: false)
          .get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.update({'checkout': true});
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut de checkout: $e');
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = cos;
    double a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(' موظف التوصيل')),
      backgroundColor: Color.fromARGB(255, 237, 238,
          239), // Changed background color to black for a sleek look
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.5, // Adjusted height
          decoration: BoxDecoration(
            border:
                Border.all(color: Color.fromARGB(255, 17, 16, 16), width: 2.0),
            borderRadius: BorderRadius.circular(
                20), // Added border radius for rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  // Changed to ElevatedButton for a more modern look
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeliveryMapPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(
                        255, 109, 172, 106), // Changed button color to blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Added border radius for rounded corners
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      'اختر موظف توصيل ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  // Changed to ElevatedButton for a more modern look
                  onPressed: () {
                    _selectSkeep();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSkeepSelected
                        ? Color.fromARGB(255, 100, 164, 112)
                        : Colors
                            .transparent, // Changed button color when selected
                    side: BorderSide(
                        color: Color.fromARGB(255, 100, 164, 112), width: 2.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Added border radius for rounded corners
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      'أقرب  موظف توصيل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: _isSkeepSelected
                            ? Color.fromARGB(255, 231, 235, 236)
                            : const Color.fromARGB(255, 15, 16,
                                16), // Changed text color when selected
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  // Changed to ElevatedButton for a more modern look
                  onPressed: () async {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final QuerySnapshot result = await FirebaseFirestore
                          .instance
                          .collection('Cart')
                          .where('clients', isEqualTo: user.uid)
                          .where('checkout', isEqualTo: false)
                          .limit(1)
                          .get();
                      final List<DocumentSnapshot> documents = result.docs;

                      if (documents.isNotEmpty) {
                        // Update the existing document
                        await FirebaseFirestore.instance
                            .collection('Cart')
                            .doc(documents.first.id)
                            .update({
                          'id_livreur': '',
                          'status': 'in progress',
                        });

                        updateCheckoutStatus();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSkeepSelected
                        ? Color.fromARGB(255, 100, 164, 112)
                        : Colors
                            .transparent, // Changed button color when selected
                    side: BorderSide(
                        color: Color.fromARGB(255, 98, 142, 90), width: 2.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Added border radius for rounded corners
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      'تخطي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: _isSkeepSelected
                            ? Color.fromARGB(255, 231, 235, 236)
                            : const Color.fromARGB(255, 12, 12,
                                12), // Changed text color when selected
                      ),
                    ),
                  ),
                ),
                if (_nearestDeliveryPersonName != null)
                  Text(
                    ' $_nearestDeliveryPersonName',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
