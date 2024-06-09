import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_application/Auth/UserInfoScreen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:my_application/livreur/bottomnavlivreu.dart';
import 'package:my_application/client/pages/bottomnav.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  OTPVerificationScreen({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  late TextEditingController _otpController;
  bool _isLoading = false;
  late Timer _timer;
  bool _canResend = false;
  bool _showResendTimer = true; // Afficher le minuteur dès le départ
  Duration _remainingTime = Duration(minutes: 2);
  bool _isCodeIncorrect = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'التحقق من الرمز',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Raleway',
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'أدخل الرمز المرسل إلى ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 60,
                    fieldWidth: 50,
                    inactiveColor: Colors.grey,
                    activeFillColor: Colors.blueGrey[800],
                    selectedColor: Colors.blueGrey[800],
                    activeColor: Colors.white,
                    selectedFillColor: Colors.blueGrey[800],
                    borderWidth: 2,
                  ),
                  animationDuration: Duration(milliseconds: 300),
                  onChanged: (value) {
                    print(value);
                  },
                  controller: _otpController,
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                    shadowColor: Colors.grey,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    height: 60,
                    width: 250,
                    child: Text(
                      'تحقق من الرمز',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : _canResend
                        ? TextButton(
                            onPressed: () {
                              _startResendTimer();
                              _resendOTP();
                            },
                            child: Text(
                              'إعادة إرسال الرمز',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Raleway',
                                color: Colors.blue,
                              ),
                            ),
                          )
                        : _showResendTimer
                            ? Text(
                                'إعادة إرسال الرمز في ${_remainingTime.inSeconds} ثانية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway',
                                  color: Colors.blue,
                                ),
                              )
                            : SizedBox.shrink(),
                _isCodeIncorrect
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'الرمز غير صحيح. الرجاء المحاولة مرة أخرى.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontFamily: 'Raleway',
                          ),
                        ),
                      )
                    : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
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
          MaterialPageRoute(builder: (context) => BottomNavLivreur()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserInfoInputScreen(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      }
    }
  }

  void _startResendTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    const oneSecond = Duration(seconds: 1);
    if (_remainingTime.inSeconds > 0) {
      setState(() {
        _remainingTime -= oneSecond;
      });
    } else {
      setState(() {
        _canResend = true;
        _showResendTimer =
            true; // Afficher le bouton de renvoi lorsque le temps est écoulé
      });
      _timer.cancel(); // Annuler le timer si le temps restant est écoulé
    }
  }

  void _verifyOTP() async {
    String enteredOTP = _otpController.text;
    if (enteredOTP.length != 6) {
      _showInvalidOTPAlert();
      return;
    }

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: enteredOTP,
    );

    try {
      setState(() {
        _isLoading = true;
        _isCodeIncorrect = false; // Réinitialiser le statut du code incorrect
      });
      await FirebaseAuth.instance.signInWithCredential(credential);
      _navigateToAppropriatePage();
    } catch (e) {
      setState(() {
        _isCodeIncorrect =
            true; // Afficher le message d'erreur pour un code incorrect
        _showResendTimer =
            true; // Afficher le bouton de renvoi lorsque le code est incorrect
      });
      _startResendTimer(); // Déclencher le renvoi du code OTP en cas d'échec de la vérification
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resendOTP() async {
    setState(() {
      _isLoading = true;
      _showResendTimer = false;
      _otpController.clear();
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: _verificationCompleted,
        verificationFailed: _verificationFailed,
        codeSent: _codeSent,
        codeAutoRetrievalTimeout: _codeAutoRetrievalTimeout,
      );
    } catch (e) {
      _showErrorSnackbar('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _codeSent(String verificationId, int? resendToken) {
    setState(() {
      _canResend = false;
      _remainingTime =
          Duration(minutes: 2); // Réinitialiser le temps à 2 minutes
      _startResendTimer();
    });
  }

  void _codeAutoRetrievalTimeout(String verificationId) {
    // Supprimer l'alerte de time out et réinitialiser le processus de renvoi du code
    setState(() {
      _showResendTimer = true;
    });
  }

  void _showErrorSnackbar(String message) {
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showInvalidOTPAlert() {
    // Afficher une alerte pour un OTP invalide
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text(
              'Le code entré est invalide. Veuillez entrer un code OTP à 6 chiffres.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _verificationCompleted(PhoneAuthCredential credential) async {
    await FirebaseAuth.instance.signInWithCredential(credential);
    _navigateToAppropriatePage();
  }

  void _verificationFailed(FirebaseAuthException e) {
    _showErrorSnackbar('Verification Failed: ${e.message}');
  }
}
