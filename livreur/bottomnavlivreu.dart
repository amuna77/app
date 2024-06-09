import 'package:flutter/material.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:my_application/livreur/delivery_status.dart';
import 'package:my_application/livreur/requests.dart';
import 'package:my_application/livreur/settings_livreur.dart'; // Importez cette bibliothèque

class BottomNavLivreur extends StatefulWidget {
  const BottomNavLivreur({Key? key});

  @override
  State<BottomNavLivreur> createState() => _BottomNavLivreurState();
}

class _BottomNavLivreurState extends State<BottomNavLivreur> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late HomeLivreur homepage;
  late Settings orders; // Remplacez Settings par Orders

  late DeliveryStatus cartScreen;

  @override
  void initState() {
    super.initState();
    homepage = HomeLivreur();
    orders = Settings(); // Initialisez Orders

    cartScreen = DeliveryStatus();
    pages = [homepage, cartScreen, orders]; // Remplacez Settings par orders
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Quitter l'application sans déconnexion
        SystemNavigator.pop();
        return false; // Empêche le retour arrière de se produire
      },
      child: Scaffold(
        bottomNavigationBar: CurvedNavigationBar(
          height: 65,
          backgroundColor: Colors.white,
          color: Colors.black,
          animationDuration: Duration(milliseconds: 500),
          onTap: (int index) {
            if (index < pages.length) {
              // Vérifiez si l'index est valide
              setState(() {
                currentTabIndex = index;
              });
            }
          },
          items: [
            Icon(
              Icons.home_outlined,
              color: Colors.white,
            ),
            Icon(
              Icons.local_shipping,
              color: Colors.white,
            ),
            Icon(
              Icons.person_outline,
              color: Colors.white,
            ),
          ],
        ),
        body: pages[currentTabIndex],
      ),
    );
  }
}
