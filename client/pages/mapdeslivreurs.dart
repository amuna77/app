import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import 'dart:async';

class DeliveryMapPage extends StatefulWidget {
  const DeliveryMapPage({Key? key}) : super(key: key);

  @override
  _DeliveryMapPageState createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage>
    with SingleTickerProviderStateMixin {
  bool accepter = false;
  static const double MAX_DISTANCE_METERS = 10; // 10 mètres
  final Completer<GoogleMapController> _controller = Completer();
  List<LatLng> _locations = [];
  Map<String, Circle> _circles = {};
  Map<String, Marker> _markers = {};
  Map<String, String> _livreurIds = {}; // Store the livreur IDs
  Timer? _timer;
  bool _showLivreurDetails = false;
  String _selectedLivreurId = '';
  String _selectedLivreurImageUrl = '';
  String _selectedLivreurName = '';
  String _selectedLivreurSurname = '';
  String _selectedLivreurPhoneNumber = '';
  DateTime _selectedLivreurDateInscription = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    _fetchDeliveryLocations();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDeliveryLocations() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('livreurs')
        .where('en_ligne', isEqualTo: true)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    double totalLatitude = 0.0;
    double totalLongitude = 0.0;

    for (var doc in querySnapshot.docs) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final double latitude = data['latitude'];
      final double longitude = data['longitude'];
      String imageUrl = data['image'];
      final String sexe = data['gender'];
      final String livreurId = doc.id; // Get the livreur ID

      if (imageUrl == '') {
        if (sexe == 'Male') {
          imageUrl = 'assets/male.png';
        } else {
          imageUrl = 'assets/female.png';
        }
      }

      totalLatitude += latitude;
      totalLongitude += longitude;

      final LatLng location = LatLng(latitude, longitude);
      _locations.add(location);
      _createCircle(location);
      _createMarker(location, imageUrl, livreurId);
    }

    double averageLatitude = totalLatitude / querySnapshot.docs.length;
    double averageLongitude = totalLongitude / querySnapshot.docs.length;

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(averageLatitude, averageLongitude),
        13.5,
      ),
    );
  }

  void _createCircle(LatLng location) {
    final Circle circle = Circle(
      circleId: CircleId(location.toString()),
      center: location,
      radius: 30,
      strokeWidth: 2,
      strokeColor: Colors.green,
      fillColor: Colors.green.withOpacity(0.3),
    );

    setState(() {
      _circles[location.toString()] = circle;
    });
  }

  void _createMarker(LatLng location, String imageUrl, String livreurId) async {
    final Marker marker = Marker(
      markerId: MarkerId(location.toString()),
      position: location,
      icon: await _createMarkerImageFromAsset(imageUrl),
      onTap: () => _showLivreurDialog(imageUrl, livreurId),
    );

    setState(() {
      _markers[location.toString()] = marker;
      _livreurIds[location.toString()] = livreurId;
    });
  }

  Future<BitmapDescriptor> _createMarkerImageFromAsset(String imagePath) async {
    ImageConfiguration configuration = ImageConfiguration();
    final ByteData byteData = await rootBundle.load(imagePath);
    final ui.Codec codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
        targetHeight: 100,
        targetWidth: 100);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final Uint8List uint8List =
        (await frameInfo.image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _updateCircles();
    });
  }

  void _updateCircles() {
    setState(() {
      _circles = _locations.asMap().map((index, location) {
        return MapEntry(
          location.toString(),
          Circle(
            circleId: CircleId(location.toString()),
            center: location,
            radius: 30 +
                10 *
                    math.sin(DateTime.now().millisecond /
                        1000), // Animate the radius
            strokeWidth: 2,
            strokeColor: Colors.green,
            fillColor: Colors.green.withOpacity(0.3),
          ),
        );
      });
    });
  }

  void _showLivreurDialog(String imageUrl, String livreurId) async {
    final DocumentSnapshot livreurDoc = await FirebaseFirestore.instance
        .collection('livreurs')
        .doc(livreurId)
        .get();
    final Map<String, dynamic> data = livreurDoc.data() as Map<String, dynamic>;
    final String name = data['name'];
    final String surname = data['surname'];
    final String phoneNumber = data['phoneNumber'];
    final Timestamp timestamp = data['date_inscription'];
    final DateTime dateInscription = timestamp.toDate();

    setState(() {
      _selectedLivreurId = livreurId;
      _selectedLivreurImageUrl = imageUrl;
      _selectedLivreurName = name;
      _selectedLivreurSurname = surname;
      _selectedLivreurPhoneNumber = phoneNumber;
      _selectedLivreurDateInscription = dateInscription;
      _showLivreurDetails = true;
    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth radius in meters
    double phi1 = _toRadians(lat1);
    double phi2 = _toRadians(lat2);
    double deltaPhi = _toRadians(lat2 - lat1);
    double deltaLambda = _toRadians(lon2 - lon1);

    double a = pow(sin(deltaPhi / 2), 2) +
        cos(phi1) * cos(phi2) * pow(sin(deltaLambda / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void _choisisLivreurToCart(String livreurId) async {
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
          'id_livreur': livreurId,
          'status': 'in progress',
          'date_status': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Livreur est choisis ...')),
        );

        // Démarrez le timer pour appeler la fonction notifierClient toutes les secondes
        // _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
        // Vérifiez si l'utilisateur est toujours connecté
        // User? currentUser = FirebaseAuth.instance.currentUser;
        // if (currentUser != null) {
        // Si oui, appelez la fonction notifierClient

        // notifierClient();
        //  }
        //});

        try {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('Cart')
              .where('clients', isEqualTo: user?.uid)
              .where('checkout', isEqualTo: false)
              .get();

          for (QueryDocumentSnapshot doc in querySnapshot.docs) {
            await doc.reference.update({'checkout': true});
          }
        } catch (e) {
          print('Erreur lors de la mise à jour du statut de checkout: $e');
        }
      }
    }
  }

  double radians(double degrees) {
    return degrees * (pi / 180);
  }

  // Méthode pour calculer la distance entre deux points géographiques

  Future<void> checkProximityAndShowSnackbar(
      String livreurId, String userId) async {
    try {
      // Récupérer les coordonnées du client
      var clientSnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .doc(userId)
          .get();

      if (!clientSnapshot.exists) {
        throw Exception("Client not found");
      }

      var clientData = clientSnapshot.data();
      if (clientData == null ||
          clientData['latitude'] == null ||
          clientData['longitude'] == null) {
        throw Exception("Client location data is missing");
      }

      var clientLatitude = clientData['latitude'];
      var clientLongitude = clientData['longitude'];

      // Récupérer les coordonnées du livreur
      var livreurSnapshot = await FirebaseFirestore.instance
          .collection('livreurs')
          .doc(livreurId)
          .get();

      if (!livreurSnapshot.exists) {
        throw Exception("Livreur not found");
      }

      var livreurData = livreurSnapshot.data();
      if (livreurData == null ||
          livreurData['latitude'] == null ||
          livreurData['longitude'] == null) {
        throw Exception("Livreur location data is missing");
      }

      var livreurLatitude = livreurData['latitude'];
      var livreurLongitude = livreurData['longitude'];

      // Vérifier le statut de la commande dans la collection Cart
      var cartQuery = await FirebaseFirestore.instance
          .collection('Cart')
          .where('id_livreur', isEqualTo: livreurId)
          .where('clients', isEqualTo: userId)
          .where('status', isEqualTo: 'shipped')
          .limit(1)
          .get();

      if (cartQuery.docs.isNotEmpty) {
        // Calculer la distance entre le client et le livreur en utilisant Geolocator
        double distance = calculateDistance(
            clientLatitude, clientLongitude, livreurLatitude, livreurLongitude);

        // Afficher la distance dans un SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('La distance est ${(distance).toInt()} mètres')),
        );

        // Verifier si le livreur est proche
        if (distance == MAX_DISTANCE_METERS) {
          //(
          //      title: "Notification Simple",
          //    body: "Le livreur est à proximité",
          //  payload: "Données de notification simple");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Aucune commande en cours de livraison trouvée')),
        );
      }
    } catch (error) {
      print('Erreur lors de la vérification de la proximité : $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Une erreur s\'est produite lors de la vérification de la proximité.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(" موظف التوصيل"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(37.33500926, -122.03272188),
              zoom: 13.5,
            ),
            mapType: MapType.normal,
            onMapCreated: (mapController) {
              _controller.complete(mapController);
              _setMapStyle(mapController);
            },
            circles: Set<Circle>.from(_circles.values),
            markers: Set<Marker>.from(_markers.values),
          ),
          if (_showLivreurDetails) _buildLivreurDetailsWidget(context),
        ],
      ),
    );
  }

  Future<void> _setMapStyle(GoogleMapController mapController) async {
    final String style = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#242f3e"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#746855"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#242f3e"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#d59563"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#d59563"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#263c3f"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#6b9a76"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#38414e"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#212a37"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9ca5b3"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#746855"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#1f2835"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#f3d19c"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#2f3948"
          }
        ]
      },
      {
        "featureType": "transit.station",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#d59563"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#17263c"
          }
        ]
      }
    ]
    ''';
    mapController.setMapStyle(style);
  }

  Widget _buildLivreurDetailsWidget(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showLivreurDetails = false;
          });
        },
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(_selectedLivreurImageUrl),
              ),
              SizedBox(height: 20),
              Text(
                '$_selectedLivreurName $_selectedLivreurSurname',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'رقم الهاتف ',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                '  $_selectedLivreurPhoneNumber',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'انضم: ${_selectedLivreurDateInscription.day}/${_selectedLivreurDateInscription.month}/${_selectedLivreurDateInscription.year}',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _choisisLivreurToCart(_selectedLivreurId);
                  setState(() {
                    _showLivreurDetails = false;
                  });
                },
                icon: Icon(Icons.send),
                label: Text("Envoyer request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
