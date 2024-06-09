import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:my_application/admin/admin_scaffold.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_application/client/pages/bottomnav.dart';
import 'package:my_application/livreur/bottomnavlivreu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Démarrer une tâche périodique pour appeler notifierClient toutes les secondes

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Brightness>(
      future: _detectBrightness(context),
      builder: (context, snapshot) {
        Brightness brightness = snapshot.data ?? Brightness.light;
        ThemeData theme = brightness == Brightness.light
            ? ThemeData.light()
            : ThemeData.dark();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('livreurs')
                        .doc(snapshot.data!.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          return BottomNavLivreur();
                        } else {
                          return BottomNav();
                        }
                      }
                    },
                  );
                } else {
                  return AdminScaffoldPage();
                }
              }),
        );
      },
    );
  }

  Future<Brightness> _detectBrightness(BuildContext context) async {
    Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);
    return platformBrightness;
  }
}
