import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_application/Auth/user_info_email.dart';
import 'package:my_application/livreur/bottomnavlivreu.dart';
import 'package:my_application/client/pages/bottomnav.dart';
import 'package:my_application/Auth/forget_password.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignIn = true;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المصادقة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Text(
                  'مرحباً',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'قم بتسجيل الدخول للمتابعة',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress, // Type d'entrée email
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'الرجاء إدخال بريد إلكتروني صالح';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.length < 8) {
                      return 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
                    }
                    // Vous pouvez ajouter des vérifications supplémentaires ici, par exemple, pour les caractères spéciaux.
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPassword(),
                      ),
                    );
                  },
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isSignIn ? _authenticate : _register,
                      child: Text(_isSignIn ? 'تسجيل الدخول' : 'التسجيل'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignIn = !_isSignIn; // Inverser l'état de connexion
                      _isLoading =
                          false; // Assurez-vous que le bouton Se connecter réapparaît
                    });
                  },
                  child: Text(
                    _isSignIn
                        ? 'ليس لديك حساب؟ التسجيل الآن'
                        : 'لديك حساب بالفعل؟ تسجيل الدخول',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _authenticate() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      setState(() {
        _isLoading = true;
      });

      try {
        final authResult =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        final user = authResult.user;

        if (user != null) {
          final clientsDoc = await FirebaseFirestore.instance
              .collection('clients')
              .where('email', isEqualTo: email)
              .get();

          if (clientsDoc.docs.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BottomNav()),
            );
          } else {
            final livreursDoc = await FirebaseFirestore.instance
                .collection('livreurs')
                .where('email', isEqualTo: email)
                .get();

            if (livreursDoc.docs.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BottomNavLivreur()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserInfoInputScreen(
                    email: email,
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        _showErrorSnackBar('Erreur de connexion : ${e}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserInfoInputScreen(
              email: email,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Inscription réussie !'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'inscription : ${e}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
