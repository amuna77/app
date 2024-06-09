import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_application/Auth/choisi_auth_methode.dart';

import 'package:my_application/client/pages/historique_orders.dart';
import 'package:my_application/client/pages/offres.dart';
import 'package:my_application/client/pages/personl_info.dart';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section du compte
              _buildSectionCard(
                title: 'الحساب',
                children: [
                  _buildListTile(
                    leadingIcon: Icons.person,
                    title: 'المعلومات الشخصية',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalInformationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 20.0),

              // Section du marché
              _buildSectionCard(
                title: 'السوق',
                children: [
                  _buildListTile(
                    leadingIcon: Icons.local_offer,
                    title: 'العروض',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Offres(),
                        ),
                      );

                      // Navigate to Offers page
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    leadingIcon: Icons.history,
                    title: 'تاريخ الطلبات',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Orders(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 20.0),

              // Section supplémentaire
              _buildSectionCard(
                title: 'إضافي',
                children: [
                  _buildListTile(
                    leadingIcon: Icons.logout,
                    title: 'تسجيل الخروج',
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Après la déconnexion, vous pouvez rediriger l'utilisateur vers l'écran de connexion
      // Par exemple:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthMethodSelectionPage()),
      );
    } catch (e) {
      print('Error during logout: $e');
      // Gérer les erreurs éventuelles ici
    }
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            SizedBox(height: 20.0),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
      {required IconData leadingIcon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(
        leadingIcon,
        color: const Color.fromARGB(255, 0, 0, 0),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: const Color.fromARGB(255, 0, 0, 0),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: const Color.fromARGB(255, 0, 0, 0),
      thickness: 1.0,
      height: 30.0,
    );
  }
}

class LanguageSelectionPage extends StatelessWidget {
  final translator = GoogleTranslator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختيار اللغة'), // "Select Language" en arabe
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _changeLanguage('fr'); // Changer la langue en français
              },
              child: Text('الفرنسية'), // "French" en arabe
            ),
            ElevatedButton(
              onPressed: () {
                _changeLanguage('en'); // Changer la langue en anglais
              },
              child: Text('الإنجليزية'), // "English" en arabe
            ),
            ElevatedButton(
              onPressed: () {
                _changeLanguage('ar'); // Changer la langue en arabe
              },
              child: Text('العربية'), // "Arabic" en arabe
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String languageCode) async {
    // Obtenez une instance de GoogleTranslator
    final translator = GoogleTranslator();

    // Traduire le texte "Settings" dans la langue cible
    final translatedText =
        await translator.translate('Settings', to: languageCode);

    // Afficher le texte traduit dans la console
    print(
        translatedText); // Ceci est un exemple, vous devez afficher le texte traduit dans votre application
  }
}
