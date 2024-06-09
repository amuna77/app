import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_admin_scaffold/admin_scaffold.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_application/admin/admin_scaffold.dart';
import 'package:my_application/admin/signin_admin/firebase_auth_helper.dart';
import 'package:my_application/admin/signup_admin/signup_admin.dart';

class AdminSignInEmail extends StatefulWidget {
  const AdminSignInEmail({super.key});

  @override
  State<AdminSignInEmail> createState() => _AdminSignInEmailState();
}

class _AdminSignInEmailState extends State<AdminSignInEmail> {
  final FirebaseAuthHelper firebaseAuthHelper = FirebaseAuthHelper();
  final TextEditingController _adminemailController = TextEditingController();
  final TextEditingController _adminpasswordController =
      TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _emailError = false;
  bool _passwordError = false;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  late User admin;

  Future<UserCredential?> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential =
            await auth.signInWithCredential(credential);
        final User user = userCredential.user!;

        // Check if any admin account exists
        final adminCollection = FirebaseFirestore.instance.collection('admin');
        final adminDocs = await adminCollection.get();

        if (adminDocs.docs.isEmpty) {
          // No admin account exists, create a new one
          await adminCollection.doc(user.uid).set({
            'username': user.displayName,
            'email': user.email,
            'profile_image': user.photoURL,
            'phone': user.phoneNumber,
          });
        } else {
          // Admin account exists, check if the user is the same
          final existingAdminDoc = adminDocs.docs.first;
          if (existingAdminDoc.id != user.uid) {
            // Different user is trying to sign in, show error
            await googleSignIn.signOut();
            await auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                  '.حساب المسؤول موجود بالفعل. الرجاء تسجيل الدخول باستخدام البريد الإلكتروني المسجل أصلا'),
              backgroundColor: Colors.red,
            ));
            return null;
          }
        }

        // Navigate to admin page or do other actions as needed
        return userCredential;
      }
    } catch (e, stackTrace) {
      print('Error signing in with Google: $e');
      print('Stack trace: $stackTrace');
    }
    return null;
  }

  // Login with Email and Password
  Future<void> _login(BuildContext context) async {
    setState(() {
      _emailError = !_isValidEmail(_adminemailController.text);
      _passwordError = _adminpasswordController.text.length < 6;
    });
    if (!_emailError && !_passwordError) {
      try {
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _adminemailController.text,
          password: _adminpasswordController.text,
        );
        final User user = userCredential.user!;

        // Fetch user's document from Firestore
        final userDoc =
            FirebaseFirestore.instance.collection('admin').doc(user.uid);
        // final userDocSnapshot = await userDoc.get();
        // if (userDocSnapshot.exists) {
        //   // Update isActive status in Firestore
        //   await userDoc.update({
        //     'isActive': true, // Set isActive to true after successful login
        //   });}
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) =>
                  const AdminScaffold(body: AdminScaffoldPage())),
        );
      } catch (e) {
        print('Login Error: $e');
        setState(() {
          _adminemailController.text = '';
          _adminpasswordController.text = '';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials.'),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 251, 249, 249),
                Color.fromARGB(255, 251, 249, 249),
                Color.fromARGB(255, 251, 249, 249),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 40,
              ),
              Image.asset(
                'assets/images/vendeur_icon.png',
                height: 130,
              ),
              const SizedBox(
                height: 12,
              ),
              Container(
                height: 650,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'يرجى تسجيل الدخول إلى حسابك',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        controller: _adminemailController,
                        decoration: InputDecoration(
                          labelText: 'البريد الالكتروني',
                          hintText: 'أدخل بريدك الإلكتروني',
                          labelStyle: TextStyle(color: Colors.black),
                          suffixIcon: const Icon(
                            FontAwesomeIcons.envelope,
                            size: 17,
                          ),
                          errorText: _emailError
                              ? 'يرجى إدخال عنوان بريد إلكتروني صالح'
                              : null,
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        controller: _adminpasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          hintText: 'ادخل كلمة المرور',
                          suffixIcon: const Icon(
                            FontAwesomeIcons.eyeSlash,
                            size: 17,
                          ),
                          errorText: _passwordError
                              ? 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل'
                              : null,
                          errorStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 50,
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => _login(context),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.black),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      'أو تسجيل الدخول باستخدام ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    GoogleAuthButton(
                      onPressed: () async {
                        UserCredential? userCredential =
                            await _signInWithGoogle(context);
                        if (userCredential != null) {
                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AdminScaffold(
                                    body: AdminScaffoldPage())),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(
                        fontFamily: "SFUIDiplay",
                        color: Color.fromARGB(255, 91, 187, 12),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const SignupAdmin()));
                      },
                      child: const Text(
                        'اشتراك',
                        style: TextStyle(
                            fontFamily: "SFUIDiplay",
                            color: Colors.black,
                            fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(email);
  }
}
