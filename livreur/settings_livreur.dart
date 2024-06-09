import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_application/Auth/choisi_auth_methode.dart';
import 'package:my_application/livreur/personal_info_livreur.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool en_ligne = false;
  bool locationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _initLocationTracking();
  }

  _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        locationPermission = true;
        en_ligne = true;
      });
    }
  }

  _initLocationTracking() {
    Geolocator.getPositionStream().listen((Position position) async {
      if (en_ligne) {
        await _updateLocation(position.latitude, position.longitude);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إعدادات',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAnimatedSwitch(),
            SizedBox(height: 20),
            _buildOptionCard(
              title: 'معلومات شخصية',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PersonalInformationPageLivreur()),
                );
              },
            ),
            SizedBox(height: 10),
            _buildOptionCard(
              title: 'تسجيل خروج',
              icon: Icons.exit_to_app,
              onTap: () {
                _signOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSwitch() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.lightGreenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            FlutterSwitch(
              width: 70.0,
              height: 35.0,
              toggleSize: 30.0,
              value: en_ligne,
              borderRadius: 20.0,
              padding: 5.0,
              showOnOff: false,
              activeText: '',
              inactiveText: '',
              activeColor: Colors.white,
              inactiveColor: Colors.white,
              activeToggleColor: Colors.green,
              inactiveToggleColor: Colors.grey,
              onToggle: (value) async {
                setState(() {
                  en_ligne =
                      value; // Mettre à jour en_ligne lors du basculement du switch
                });
                if (value) {
                  // Si le switch est activé
                  bool locationGranted = await _getLocationAndStore();
                  if (!locationGranted) {
                    // Si l'utilisateur refuse de donner la localisation, désactivez le switch
                    setState(() {
                      en_ligne = false;
                    });
                  } else {
                    // Si la localisation est accordée, mettez à jour en_ligne à true dans la base de données
                    await _toggleEnLigne(true);
                  }
                } else {
                  // Si le switch est désactivé, mettre à jour en_ligne à false dans la base de données
                  await _toggleEnLigne(false);
                }
              },
            ),
            SizedBox(width: 10),
            Text(
              'جاهز للعمل ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: Icon(
            icon,
            color: Colors.blue,
            size: 30,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleEnLigne(bool value) async {
    try {
      if (value == true) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        await FirebaseFirestore.instance
            .collection('livreurs')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'en_ligne': value,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('livreurs')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'en_ligne': value,
          'latitude': null,
          'longitude': null,
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut en_ligne: $e');
    }
  }

  Future<void> _updateLocation(double latitude, double longitude) async {
    try {
      await FirebaseFirestore.instance
          .collection('livreurs')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la localisation: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthMethodSelectionPage()),
      );
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // Fonction pour obtenir la localisation et stocker dans la base de données
  Future<bool> _getLocationAndStore() async {
    try {
      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      // Stocker la position dans la base de données
      await _updateLocation(position.latitude, position.longitude);
      return true;
    } catch (e) {
      print('Erreur lors de l\'obtention de la localisation: $e');
      return false;
    }
  }
}
