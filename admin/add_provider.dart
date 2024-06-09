import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:my_application/admin/telephone_input_formatter.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class AddProvider extends StatefulWidget {
  static const String routeName = '/add_provider_screen';

  const AddProvider({super.key});
  @override
  State<AddProvider> createState() => _AddProviderState();
}

class _AddProviderState extends State<AddProvider> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  final _globalKey = GlobalKey<FormState>();
  final providerNameController = TextEditingController();
  final addresseController = TextEditingController();
  final villeController = TextEditingController();
  final providerEmailController = TextEditingController();
  final providerphoneController = TextEditingController();

  Future<void> _addProvider() async {
    if (_globalKey.currentState!.validate()) {
      try {
        DocumentReference providerRef =
            await firestore.collection('providers').add({
          'name': providerNameController.text,
          'address': addresseController.text,
          'ville': villeController.text,
          'providerEmail': providerEmailController.text,
          'provderPhone': providerphoneController.text,
          'timeStampe': FieldValue.serverTimestamp(),
        });
        print('Provider added succefully: ${providerRef.id}');

        _globalKey.currentState!.reset();
        providerNameController.clear();
        providerEmailController.clear();
        providerphoneController.clear();
        addresseController.clear();
        villeController.clear();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('.تمت إضافة المورد بنجاح'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        print('Error: $e');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('حدث خطأ. حاول مرة اخرى.'),
              backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('حدث خطأ. حاول مرة اخرى.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.teal.shade400.withOpacity(.8),
          title: const Center(
            child: Text(
              'اضافة مورد',
              // textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 35),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _globalKey,
            child: Column(
              children: [
                Title(
                  color: Colors.black,
                  child: const SizedBox(
                    child: Text(
                      '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                      textWidthBasis: TextWidthBasis.parent,
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    controller: providerNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المورد',
                      hintText: 'ادخل اسم المورد',
                      suffixIcon: Icon(
                        FontAwesomeIcons.user,
                      ),
                      border: GradientOutlineInputBorder(
                        gradient: LinearGradient(
                            colors: [Colors.black, Colors.black]),
                        width: 2,
                      ),
                      focusedBorder: GradientOutlineInputBorder(
                          gradient: LinearGradient(
                              colors: [Colors.green, Colors.green]),
                          width: 2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء ادخال اسم المورد';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    controller: addresseController,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(
                        FontAwesomeIcons.addressCard,
                      ),
                      hintText: 'ادخل عنوان المورد',
                      labelText: 'العنوان',
                      border: GradientOutlineInputBorder(
                        gradient: LinearGradient(
                            colors: [Colors.black, Colors.black]),
                        width: 2,
                      ),
                      focusedBorder: GradientOutlineInputBorder(
                          gradient: LinearGradient(
                              colors: [Colors.green, Colors.green]),
                          width: 2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء ادخال عنوان المورد';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    controller: villeController,
                    decoration: const InputDecoration(
                      labelText: 'المدينة',
                      hintText: 'ادخل مدينة المورد',
                      suffixIcon: const Icon(
                        FontAwesomeIcons.city,
                        color: Colors.black,
                      ),
                      border: GradientOutlineInputBorder(
                        gradient: LinearGradient(
                            colors: [Colors.black, Colors.black]),
                        width: 2,
                      ),
                      focusedBorder: GradientOutlineInputBorder(
                          gradient: LinearGradient(
                              colors: [Colors.green, Colors.green]),
                          width: 2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء ادخال مدينة المورد';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    controller: providerEmailController,
                    decoration: const InputDecoration(
                      labelText: 'البريد الالكتروني',
                      hintText: ' ادخل البريد الالكتروني للمورد',
                      suffixIcon: const Icon(
                        FontAwesomeIcons.envelope,
                        color: Colors.black,
                      ),
                      border: GradientOutlineInputBorder(
                        gradient: LinearGradient(
                            colors: [Colors.black, Colors.black]),
                        width: 2,
                      ),
                      focusedBorder: GradientOutlineInputBorder(
                          gradient: LinearGradient(
                              colors: [Colors.green, Colors.green]),
                          width: 2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء ادخال البريد الالكتروني للمورد';
                      } else if (!_isEmailValid(value)) {
                        return '(e.g., Gmail, Yahoo, Hotmail)الرجاء إدخال عنوان البريد الإلكتروني المستخدم بشكل متكرر ';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {
                      if (_isEmailValid(value)) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            const DecoratedBox(
                              decoration:
                                  BoxDecoration(shape: BoxShape.rectangle),
                            );
                            var dialogController = Completer();
                            Timer(const Duration(seconds: 1), () {
                              if (!dialogController.isCompleted) {
                                dialogController.complete();
                                Navigator.pop(context);
                              }
                            });
                            return const AlertDialog(
                              title: Text(
                                '!يستخدم بشكل متكرر',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    controller: providerphoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                      TelephoneInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      hintText: 'ادخل رقم هاتف المورد',
                      suffixIcon: Icon(
                        FontAwesomeIcons.phone,
                      ),
                      border: GradientOutlineInputBorder(
                        gradient: LinearGradient(
                            colors: [Colors.black, Colors.black]),
                        width: 2,
                      ),
                      focusedBorder: GradientOutlineInputBorder(
                          gradient: LinearGradient(
                              colors: [Colors.green, Colors.green]),
                          width: 2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء ادخل رقم هاتف المورد';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 30.0,
                ),
                GestureDetector(
                  onTap: () {
                    _addProvider();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    width: 200,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        "اضافة المورد",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    final frequentlyUsedDomains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
    ];

    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    final domain = email.split('@').last.toLowerCase();

    return frequentlyUsedDomains.contains(domain);
  }
}

class Provider extends StatefulWidget {
  static const String routeName = '/provider_screen';

  const Provider({super.key});

  @override
  State<Provider> createState() => _ProviderState();
}

class _ProviderState extends State<Provider> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _deliveryStream;

  late String id;

  @override
  void initState() {
    super.initState();
    _deliveryStream = FirebaseFirestore.instance
        .collection('providers')
        .orderBy('timeStampe', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(children: [
            SizedBox(
              height: 20,
            ),
            Title(
              color: Colors.black,
              child: const SizedBox(
                child: Text(
                  'الموردين',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                  textWidthBasis: TextWidthBasis.parent,
                ),
              ),
            ),
            Container(
                child: StreamBuilder<QuerySnapshot>(
              stream: _deliveryStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor: const Color(0xFF1A1A3F),
                      rightDotColor: const Color(0xFFEA3799),
                      size: 50,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.none) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا يتوفر اتصال بالإنترنت'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }

                final List<QueryDocumentSnapshot> documents =
                    snapshot.data!.docs;

                return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                        dragStartBehavior: DragStartBehavior.start,
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                            columnSpacing: 6,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'الاسم',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.deepOrange),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'العنوان',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.deepOrange),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'المعلومات الشخصية',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.deepOrange),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Action',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.deepOrange),
                                ),
                              ),
                            ],
                            rows: documents.map((doc) {
                              final Map<String, dynamic> data =
                                  doc.data() as Map<String, dynamic>;
                              final String name = data['name'] ?? '';
                              final String address = data['address'] ?? '';
                              final String ville = data['address'] ?? '';
                              final String phone = data['provderPhone'] ?? '';
                              final String email = data['providerEmail'] ?? '';

                              final String id = doc.id;

                              return DataRow(
                                cells: [
                                  DataCell(Text(name)),
                                  DataCell(Row(
                                    children: [
                                      Text(ville),
                                      const SizedBox(
                                        width: 2,
                                      ),
                                      Text(address),
                                    ],
                                  )),
                                  DataCell(Center(
                                      child: Column(
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(email),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Text(phone),
                                    ],
                                  ))),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent),
                                            onPressed: () async {
                                              try {
                                                CollectionReference products =
                                                    await firestore.collection(
                                                        'providers');

                                                await products.doc(id).delete();

                                                print(
                                                    'Provider deleted succesfully');
                                              } catch (e) {
                                                print(
                                                    'Error deleting provider: $e');
                                              }
                                            }),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            sortColumnIndex: 1,
                            sortAscending: true,
                            horizontalMargin: 20,
                            dataTextStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                            dataRowColor:
                                MaterialStateColor.resolveWith((states) {
                              return states.contains(MaterialState.selected)
                                  ? Colors.transparent
                                  : Colors.blueGrey.withOpacity(0.1);
                            }),
                            dataRowMaxHeight: 80,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(),
                              ),
                            ))));
              },
            )),
          ])),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(SwipeablePageRoute(
            canOnlySwipeFromEdge: true,
            builder: (BuildContext context) => const AddProvider(),
          ));
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
