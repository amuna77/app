import 'dart:io';

import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_application/admin/admin_scaffold.dart';
import 'package:my_application/admin/telephone_input_formatter.dart';

class SignupAdmin extends StatefulWidget {
  const SignupAdmin({super.key});

  @override
  State<SignupAdmin> createState() => _SignupAdminState();
}

class _SignupAdminState extends State<SignupAdmin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _email = TextEditingController();
  final _username = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmpassword = TextEditingController();
  File? _profileImage;

  bool _emailError = false;
  bool _userError = false;
  bool _addressError = false;
  bool _phoneError = false;
  bool _passwordError = false;
  bool _confirmpasswordError = false;
  final bool _isActive = true;

  Future<void> _signUpAdmin(BuildContext context) async {
    setState(() {
      _emailError = !_isValidEmail(_email.text);
      _userError = _username.text.isEmpty;
      _addressError = _address.text.isEmpty;
      _phoneError = _phone.text.isEmpty;
      _passwordError = _password.text.isEmpty || _password.text.length < 6;
      _confirmpasswordError = _confirmpassword.text.isEmpty ||
          _confirmpassword.text != _password.text;
    });

    if (!_emailError &&
        !_userError &&
        !_addressError &&
        !_phoneError &&
        !_passwordError &&
        !_confirmpasswordError) {
      try {
        final adminSnapshot =
            await _firestore.collection('admin').limit(1).get();
        if (adminSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يوجد بالفعل حساب مسؤول '),
              backgroundColor: Colors.red,
            ),
          );
          // throw 'يوجد بالفعل حساب مسؤول ';
        }

        if (adminSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يوجد بالفعل حساب مسؤول بهذا البريد الإلكتروني '),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (_password.text != '${_username.text}@234') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' yousername@234 كلمة المرور غير آمنة: من الشكل'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (_password.text != _confirmpassword.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('كلمة المرور غير مطابقة'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (_email.text.length < 13) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('البريد غير متطابق'),
              backgroundColor: Colors.red,
            ),
          );
        }

        final UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email.text,
          password: _password.text,
        );
        if (_profileImage != null) {
          final Reference ref = _storage
              .ref()
              .child('admin_profile/${userCredential.user!.uid}.jpg');
          await ref.putFile(_profileImage!);
          final String downloadURL = await ref.getDownloadURL();
          await _firestore
              .collection('admin')
              .doc(userCredential.user!.uid)
              .set({
            'email': _email.text,
            'password': _password.text,
            'username': _username.text,
            'address': _address.text,
            'phone': _phone.text,
            'profile_image': downloadURL,
            'isActive': _isActive,
          });
        } else {
          await _firestore
              .collection('admin')
              .doc(userCredential.user!.uid)
              .set({
            'email': _email.text,
            'password': _password.text,
            'username': _username.text,
            'phone': _phone.text,
          });
        }
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) =>
                  const AdminScaffold(body: AdminScaffoldPage())),
        );
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التسجيل بنجاح. '),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Sign-up error: $e');
        setState(() {
          _email.text = '';
          _username.text = '';
          _address.text = '';
          _phone.text = '';
          _password.text = '';
          _confirmpassword.text = '';
          _profileImage = null;

          if (e is FirebaseAuthException) {
            if (e.code == 'email-already-in-use') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'حقل التسجيل: عنوان البريد الإلكتروني قيد الاستخدام بالفعل بواسطة حساب آخر.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else if (e is FirebaseException &&
              e.code == 'firebase_storage/object-not-found') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'فشل تحميل صورة الملف الشخصي: لا يوجد كائن في المرجع المطلوب.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    try {
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });

        print('Image picked: $_profileImage');

        // Upload image to Firebase Storage
        final Reference storageRef = FirebaseStorage.instance.ref().child(
            'admin_profile/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final UploadTask uploadTask = storageRef.putFile(_profileImage!);

        uploadTask.whenComplete(() async {
          try {
            final String downloadURL = await storageRef.getDownloadURL();

            print('Image uploaded. Download URL: $downloadURL');

            // ignore: use_build_context_synchronously
            _signUpAdmin(context);
          } catch (e) {
            print('Error getting download URL: $e');
          }
        });

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print(
              'Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        reverse: true,
        padding: const EdgeInsets.all(60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 900,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.center,
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
                    height: 8,
                  ),
                  const Text(
                    'التسجيل',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 550,
                    child: TextFormField(
                      textAlign: TextAlign.end,
                      controller: _username,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        labelStyle: TextStyle(
                          color: Colors.black,
                        ),
                        hintText: 'ادخل اسم المتسخدم',
                        suffixIcon: const Icon(
                          FontAwesomeIcons.user,
                        ),
                        border: const GradientOutlineInputBorder(
                          gradient: LinearGradient(colors: [
                            Colors.black,
                            Color.fromARGB(255, 15, 65, 106)
                          ]),
                          width: 2,
                        ),
                        focusedBorder: const GradientOutlineInputBorder(
                            gradient: LinearGradient(
                                colors: [Colors.green, Colors.green]),
                            width: 2),
                        errorText:
                            _userError ? 'يرجي ادخال اسة المستخدم ' : null,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 550,
                    child: TextFormField(
                      controller: _address,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        labelText: 'العنوان',
                        hintText: 'ادخل عنوانك',
                        suffixIcon: const Icon(
                          FontAwesomeIcons.addressCard,
                        ),
                        border: const GradientOutlineInputBorder(
                          gradient: LinearGradient(colors: [
                            Colors.black,
                            Color.fromARGB(255, 15, 65, 106)
                          ]),
                          width: 2,
                        ),
                        focusedBorder: const GradientOutlineInputBorder(
                            gradient: LinearGradient(
                                colors: [Colors.green, Colors.green]),
                            width: 2),
                        errorText: _addressError
                            ? 'يرجى ادخال العنوان الخاص بك '
                            : null,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 550,
                    child: TextFormField(
                      textAlign: TextAlign.end,
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                        TelephoneInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف',
                        suffixIcon: const Icon(
                          FontAwesomeIcons.phone,
                        ),
                        border: const GradientOutlineInputBorder(
                          gradient: LinearGradient(colors: [
                            Colors.black,
                            Color.fromARGB(255, 15, 65, 106)
                          ]),
                          width: 2,
                        ),
                        focusedBorder: const GradientOutlineInputBorder(
                            gradient: LinearGradient(
                                colors: [Colors.green, Colors.green]),
                            width: 2),
                        errorText: _phoneError ? 'يرجى ادخا رقم الهاتف ' : null,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 550,
                    child: TextFormField(
                      textAlign: TextAlign.end,
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: 'البريد الالكتروني',
                        hintText: 'your_addresse@gmail.com',
                        suffixIcon: const Icon(
                          FontAwesomeIcons.envelope,
                          color: Colors.black,
                        ),
                        errorText: _emailError
                            ? 'يرجى إدخال عنوان بريد إلكتروني صالح'
                            : null,
                        errorStyle: const TextStyle(color: Colors.red),
                        border: const GradientOutlineInputBorder(
                          gradient: LinearGradient(colors: [
                            Colors.black,
                            Color.fromARGB(255, 15, 65, 106)
                          ]),
                          width: 2,
                        ),
                        focusedBorder: const GradientOutlineInputBorder(
                            gradient: LinearGradient(
                                colors: [Colors.green, Colors.green]),
                            width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 550,
                    child: TextFormField(
                      textAlign: TextAlign.end,
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: 'ادخل كلمة المرور',
                        suffixIcon: const Icon(
                          FontAwesomeIcons.eyeSlash,
                          size: 20,
                        ),
                        border: const GradientOutlineInputBorder(
                          gradient: LinearGradient(colors: [
                            Colors.black,
                            Color.fromARGB(255, 15, 65, 106)
                          ]),
                          width: 2,
                        ),
                        focusedBorder: const GradientOutlineInputBorder(
                            gradient: LinearGradient(
                                colors: [Colors.green, Colors.green]),
                            width: 2),
                        errorText: _passwordError
                            ? 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل'
                            : null,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 550,
                    child: TextFormField(
                      textAlign: TextAlign.end,
                      controller: _confirmpassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        hintText: 'تأكيد كلمة المرور',
                        suffixIcon: const Icon(
                          FontAwesomeIcons.eyeSlash,
                          size: 20,
                        ),
                        border: const GradientOutlineInputBorder(
                          gradient: LinearGradient(colors: [
                            Colors.black,
                            Color.fromARGB(255, 15, 65, 106)
                          ]),
                          width: 2,
                        ),
                        focusedBorder: const GradientOutlineInputBorder(
                            gradient: LinearGradient(
                                colors: [Colors.green, Colors.green]),
                            width: 2),
                        errorText: _confirmpasswordError
                            ? 'حاول تاكيد كلمة المرور مرة اخرى '
                            : null,
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    "قم بتحميل الصورة",
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20.0),
                  GestureDetector(
                    onTap: () {
                      _uploadImage();
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.add_a_photo)
                          : Container(),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    height: 50,
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => _signUpAdmin(context),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.black),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(email);
  }
}
