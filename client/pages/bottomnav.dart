import 'package:flutter/material.dart';

import 'package:my_application/client/pages/home.dart';
import 'package:my_application/client/pages/order.dart'; // Importez Orders ici
import 'package:my_application/client/pages/settings/presentation/settings/settings.dart';
import 'package:my_application/client/pages/wishlist.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart'; // Importez cette bibliothèque

class BottomNav extends StatefulWidget {
  const BottomNav({Key? key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late Home homepage;
  late Settings orders; // Remplacez Settings par Orders
  late WishlistScreen wishlistScreen;
  late CartScreen cartScreen;

  @override
  void initState() {
    super.initState();
    homepage = Home();
    orders = Settings(); // Initialisez Orders
    wishlistScreen = WishlistScreen();
    cartScreen = CartScreen();
    pages = [
      homepage,
      wishlistScreen,
      cartScreen,
      orders
    ]; // Remplacez Settings par orders
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
              Icons.favorite_outline,
              color: Colors.white,
            ),
            Icon(
              Icons.shopping_cart_outlined,
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
