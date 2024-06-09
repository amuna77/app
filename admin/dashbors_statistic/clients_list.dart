import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class ClientList extends StatefulWidget {
  static const String routeName = '/client';

  const ClientList({super.key});

  @override
  State<ClientList> createState() => _ClientListState();
}

class _ClientListState extends State<ClientList> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  late Stream<QuerySnapshot> _deliveryStream;

  late String id;

  @override
  void initState() {
    super.initState();
    _deliveryStream = FirebaseFirestore.instance
        .collection('clients')
        .orderBy('date_inscription', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(children: [
        SizedBox(
          height: 27,
        ),
        Title(
          color: Colors.black,
          child: const SizedBox(
            child: Text(
              'العملاء',
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

            final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

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
                    final String imageURL = data['image'] ?? '';
                    // bool isActive = data['en_ligne'] ?? false;

                    final String id = doc.id;

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    imageURL != null && imageURL.isNotEmpty
                                        ? NetworkImage(imageURL!)
                                        : AssetImage('assets/images/client.png')
                                            as ImageProvider,
                                radius: 25,
                              ),
                              // const SizedBox(width: 3),
                              // CircleAvatar(
                              //   backgroundColor: isActive ? Colors.green : Colors.red,
                              //   radius: 8,
                              // ),
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
                                  Navigator.of(context).push(SwipeablePageRoute(
                                    canOnlySwipeFromEdge: true,
                                    builder: (BuildContext context) =>
                                        ClientProfile(clientId: id),
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
                  dataTextStyle: const TextStyle(fontWeight: FontWeight.bold),
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
      ]),
    );
  }
}

// Client Profile
class ClientProfile extends StatefulWidget {
  final String clientId;

  const ClientProfile({required this.clientId});

  @override
  State<ClientProfile> createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.teal.shade400.withOpacity(.8),
            title: const Center(
              child: Text(
                'معلومات العميل',
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
                  .collection('clients')
                  .doc(widget.clientId)
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
                  return const Center(child: Text('لم يتم العثور على عميل '));
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

                final client = Client.fromFirestore(snapshot.data!);

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            backgroundImage: client.image.isNotEmpty
                                ? NetworkImage(client.image) as ImageProvider
                                : AssetImage('assets/images/client.png'),
                            radius: 60,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(client.name, ' :اللقب'),
                        const SizedBox(height: 10),
                        _buildInfoRow(client.surname, ' :الاسم'),
                        const SizedBox(height: 10),
                        _buildInfoRow(client.address, ' :العنوان'),
                        const SizedBox(height: 10),
                        _buildInfoRow(client.email, ' :البريد الإلكتروني'),
                        const SizedBox(height: 10),
                        _buildInfoRow(client.gender, ' :الجنس'),
                        const SizedBox(height: 10),
                        _buildInfoRow(client.phoneNumber, ' :رقم الهاتف'),
                        const SizedBox(height: 10),
                        _buildInfoRow(client.signupDate.toDate().toString(),
                            ' :تاريخ التسجيل'),
                      ],
                    ),
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

class Client {
  final String name;
  final String surname;
  final String address;
  final String email;
  final String gender;
  final String image;
  final String phoneNumber;
  final Timestamp signupDate;

  Client({
    required this.name,
    required this.surname,
    required this.address,
    required this.email,
    required this.gender,
    required this.image,
    required this.phoneNumber,
    required this.signupDate,
  });

  factory Client.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Client(
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      image: data['image'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      signupDate: data['date_inscrption'] ?? Timestamp.now(),
    );
  }
}
