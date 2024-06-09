import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_application/auth/OTPVerificationScreen.dart';
import 'package:my_application/auth/UserInfoScreen.dart';

import 'package:my_application/client/pages/bottomnav.dart';
import 'package:my_application/livreur/requests.dart';

class PhoneNumberInputScreen extends StatefulWidget {
  @override
  _PhoneNumberInputScreenState createState() => _PhoneNumberInputScreenState();
}

class _PhoneNumberInputScreenState extends State<PhoneNumberInputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _countryCodeController =
      TextEditingController(text: '+213');
  late AnimationController _animationController;
  late Animation<double>? _animation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToAppropriatePage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot clientSnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .doc(user.uid)
          .get();
      DocumentSnapshot livreurSnapshot = await FirebaseFirestore.instance
          .collection('livreurs')
          .doc(user.uid)
          .get();

      if (clientSnapshot.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNav()),
        );
      } else if (livreurSnapshot.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeLivreur()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserInfoInputScreen(
              phoneNumber: user.phoneNumber ?? "",
            ),
          ),
        );
      }
      _stopLoading(); // Arrête le chargement après la navigation
    }
  }

  Future<void> _verifyPhoneNumber() async {
    String phoneNumber = _phoneNumberController.text.trim();

    if (phoneNumber.isEmpty) {
      _showErrorSnackbar('Please enter a phone number.');
      return;
    }

    String formattedPhoneNumber = _countryCodeController.text + phoneNumber;

    try {
      _startLoading();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _navigateToAppropriatePage();
        },
        verificationFailed: (FirebaseAuthException e) {
          _stopLoading();
          _showErrorSnackbar('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _startLoading(); // Démarre le chargement avant la navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                verificationId: verificationId,
                phoneNumber: formattedPhoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _stopLoading();
          _showErrorSnackbar('Timeout: Code not received. Please try again.');
        },
      );
    } catch (e) {
      _stopLoading();
      print('Error caught: $e');

      if (e is FirebaseAuthException && e.code == 'blocked') {
        _showErrorSnackbar(
            'Phone verification blocked. Please try again later.');
      } else {
        _showErrorSnackbar('Error: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        margin: EdgeInsets.symmetric(horizontal: 25, vertical: 35),
        elevation: 10,
      ),
    );
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _stopLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'التحقق من الهاتف',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          SingleChildScrollView(
            child: FadeTransition(
              opacity: _animation!,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/phone_verification.jpeg',
                      height: 200,
                    ),
                    SizedBox(height: 30),
                    Text(
                      'الرجاء إدخال رقم هاتفك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'سنقوم بإرسال رمز التحقق عبر الرسائل القصيرة SMS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 242, 239, 239),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _countryCodeController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabled: false,
                              hintText: '+213',
                              hintStyle: TextStyle(color: Colors.blueAccent),
                            ),
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 242, 239, 239),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _phoneNumberController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'رقم الهاتف',
                                hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 29, 30, 30),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: _verifyPhoneNumber,
                      child: Text(
                        'التحقق من رقم الهاتف',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    Text(
                      '  من خلال النقر على التحقق من رقم الهاتف ،  قد يتم إرسال رسالة نصية قصيرة ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: SpinKitThreeBounce(
                    color: Colors.white,
                    size: 50.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
