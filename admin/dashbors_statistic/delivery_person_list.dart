import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class DeliveryPerson extends StatefulWidget {
  const DeliveryPerson({super.key});

  @override
  State<DeliveryPerson> createState() => _DeliveryPersonState();
}

class _DeliveryPersonState extends State<DeliveryPerson> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  late Stream<QuerySnapshot> _deliveryStream;

  late String id;

  @override
  void initState() {
    super.initState();
    _deliveryStream = FirebaseFirestore.instance
        .collection('livreurs')
        .orderBy('date_inscription', descending: true)
        .snapshots();
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
              'عمال التوصيل',
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
          scrollDirection: Axis.vertical,
          child: Column(children: [
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
                            'الصورة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepOrange),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'الاسم',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepOrange),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'رقم الهاتف',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepOrange),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action',
                            textAlign: TextAlign.center,
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
                        final String surname = data['surname'] ?? '';
                        final String phone = data['phoneNumber'] ?? '';

                        bool isActive = data['en_ligne'] ?? false;

                        final String id = doc.id;

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  const SizedBox(width: 3),
                                  CircleAvatar(
                                    backgroundColor:
                                        isActive ? Colors.green : Colors.red,
                                    radius: 8,
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Row(
                              children: [
                                Text(name),
                                const SizedBox(
                                  width: 2,
                                ),
                                Text(surname)
                              ],
                            )),
                            DataCell(Text(phone)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.person_search_sharp,
                                        color: Colors.amberAccent),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(SwipeablePageRoute(
                                        canOnlySwipeFromEdge: true,
                                        builder: (BuildContext context) =>
                                            DeliveryProfile(deliveryId: id),
                                      ));
                                    },
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () {
                                        // ProductServices services = ProductServices();
                                        // services.deleteProduct(id);
                                      }),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      sortColumnIndex: 1,
                      sortAscending: true,
                      dataTextStyle:
                          const TextStyle(fontWeight: FontWeight.bold),
                      dataRowColor: MaterialStateColor.resolveWith((states) {
                        return states.contains(MaterialState.selected)
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.1);
                      }),
                      dataRowMaxHeight: 60,
                    ),
                  ),
                );
              },
            )),
          ])),
    );
  }
}

// Delivery Profile
class DeliveryProfile extends StatefulWidget {
  final String deliveryId;

  const DeliveryProfile({required this.deliveryId});

  @override
  State<DeliveryProfile> createState() => _DeliveryProfileState();
}

class _DeliveryProfileState extends State<DeliveryProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.teal.shade400.withOpacity(.8),
            title: const Center(
              child: Text(
                'معلومات عامل التوصيل',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
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
          reverse: true,
          child: Column(children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('livreurs')
                  .doc(widget.deliveryId)
                  .get(),
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

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                      child: Text('لم يتم العثور على عامل التوصيل'));
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

                final delivery = Delivery.fromFirestore(snapshot.data!);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Center(
                        child: CircleAvatar(
                          backgroundImage: delivery.image.isNotEmpty
                              ? NetworkImage(delivery.image) as ImageProvider
                              : AssetImage('assets/images/client.png'),
                          radius: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(delivery.name, ' :اللقب'),
                      const SizedBox(height: 10),
                      _buildInfoRow(delivery.surname, ' :الاسم'),
                      const SizedBox(height: 10),
                      _buildInfoRow(delivery.address, ' :العنوان'),
                      const SizedBox(height: 10),
                      _buildInfoRow(delivery.email, ' :البريد الإلكتروني'),
                      const SizedBox(height: 10),
                      _buildInfoRow(delivery.gender, ' :الجنس'),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      _buildInfoRow(delivery.phoneNumber, ' :رقم الهاتف'),
                      const SizedBox(height: 10),
                      _buildInfoRow(delivery.signupDate.toDate().toString(),
                          ' :تاريخ التسجيل'),
                    ],
                  ),
                );
              },
            ),
          ]),
        ));
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class Delivery {
  final String name;
  final String surname;
  final String address;
  final String email;
  final String gender;
  final String image;
  final int reviews;
  final String phoneNumber;
  final Timestamp signupDate;

  Delivery({
    required this.name,
    required this.surname,
    required this.address,
    required this.email,
    required this.gender,
    required this.image,
    required this.reviews,
    required this.phoneNumber,
    required this.signupDate,
  });

  factory Delivery.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Delivery(
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      image: data['image'] ?? '',
      reviews: data['reviews'] ?? 0,
      phoneNumber: data['phoneNumber'] ?? '',
      signupDate: data['signup_date'] ?? Timestamp.now(),
    );
  }
}
