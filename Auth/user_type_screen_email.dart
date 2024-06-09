import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_application/livreur/bottomnavlivreu.dart';
import 'package:my_application/client/pages/bottomnav.dart';

class UserTypeSelectionScreenEmail extends StatefulWidget {
  final String name;
  final String surname;
  final String gender;
  final String email;

  UserTypeSelectionScreenEmail({
    required this.name,
    required this.surname,
    required this.gender,
    required this.email,
  });

  @override
  _UserTypeSelectionScreenEmailState createState() =>
      _UserTypeSelectionScreenEmailState();
}

class _UserTypeSelectionScreenEmailState
    extends State<UserTypeSelectionScreenEmail> {
  String _selectedUserType = 'client'; // Par défaut client

  void _selectUserType(String userType) {
    setState(() {
      _selectedUserType = userType;
    });
  }

  Future<void> _saveUserInfoAndNavigate(
      BuildContext context, String userType) async {
    final user = {
      'name': widget.name,
      'surname': widget.surname,
      'gender': widget.gender,
      'phoneNumber': '',
      'date_inscription': Timestamp.now(),
      'email': widget.email,
      'image': '' // String without value
    };

    final userUid = FirebaseAuth.instance.currentUser!.uid;

    if (userType == 'client') {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(userUid)
          .set(user);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNav()),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('livreurs')
          .doc(userUid)
          .set(user);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavLivreur()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choice\nAre you a customer or delivery person?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  _selectUserType('client');
                  _saveUserInfoAndNavigate(context, 'client');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedUserType == 'client'
                      ? Colors.green
                      : const Color.fromARGB(255, 0, 0, 0),
                  padding:
                      EdgeInsets.all(20), // Ajustez la taille du bouton ici
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size(double.infinity, 0),
                ),
                child: Text(
                  'Customer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedUserType == 'client'
                        ? Color.fromARGB(255, 255, 253, 253)
                        : Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _selectUserType('livreur');
                  _saveUserInfoAndNavigate(context, 'livreur');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedUserType == 'livreur'
                      ? Colors.green
                      : const Color.fromARGB(255, 0, 0, 0),
                  padding:
                      EdgeInsets.all(20), // Ajustez la taille du bouton ici
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size(double.infinity, 0),
                ),
                child: Text(
                  'Delivery ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedUserType == 'livreur'
                        ? Color.fromARGB(255, 0, 0, 0)
                        : const Color.fromARGB(255, 255, 252, 252),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
