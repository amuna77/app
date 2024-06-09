import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:group_list_view/group_list_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class WaitingOredrs extends StatefulWidget {
  const WaitingOredrs({super.key});

  @override
  State<WaitingOredrs> createState() => _WaitingOredrsState();
}

class _WaitingOredrsState extends State<WaitingOredrs> {
  late Stream<QuerySnapshot> _ordersStream;
  FirebaseStorage storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _ordersStream = FirebaseFirestore.instance
        .collection('Cart')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> fetchLivreurs() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('livreurs')
        .where('en_ligne', isEqualTo: true)
        .get();

    return querySnapshot.docs.map((doc) {
      return {'id': doc.id, 'name': doc['name'], 'surname': doc['surname']};
    }).toList();
  }

// add dleivery person to cart
  Future<void> updateOrderWithLivreur(String orderId, String livreurId) async {
    await FirebaseFirestore.instance.collection('Cart').doc(orderId).update({
      'id_livreur': livreurId,
      'status': 'in progress',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم اضافت عامل التوصيل للطلب بنجاح'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showLivreurDialog(String orderId) async {
    List<Map<String, dynamic>> livreurs = await fetchLivreurs();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titleTextStyle:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
          title: const Text(
            'اختر عامل التوصيل',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: livreurs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  selectedColor: Colors.teal,
                  title: Row(
                    children: [
                      Text(
                          '${livreurs[index]['name']} ${livreurs[index]['surname']}'),
                    ],
                  ),
                  onTap: () {
                    updateOrderWithLivreur(orderId, livreurs[index]['id']);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
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
                'طلبات في انتظار',
                // textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: _ordersStream,
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

              final List<QueryDocumentSnapshot> documents =
                  snapshot.data!.docs.where((doc) {
                var idLivreur = doc['id_livreur'];
                var checkout = doc['checkout'];
                return (idLivreur == null ||
                        (idLivreur is String && idLivreur.isEmpty)) &&
                    checkout == true;
              }).toList();

              if (documents.isEmpty) {
                return const Center(
                  child: Text('No orders available',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                );
              }

              return GroupListView(
                sectionsCount: documents.length,
                countOfItemInSection: (int section) => 1,
                itemBuilder: (BuildContext context, IndexPath indexPath) {
                  var order = documents[indexPath.section];
                  return ExpansionTile(
                    iconColor: Colors.teal,
                    collapsedShape: const StadiumBorder(
                      side: BorderSide(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      side: const BorderSide(color: Colors.teal, width: 2.0),
                    ),
                    title: Text(
                      "Order ID: ${order.id}",
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Price:${order['total_price']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ]),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.teal),
                            // shape: ,
                          ),
                          onPressed: () {
                            showLivreurDialog(order.id);
                          },
                          child: const Text(
                            'Add delivery person',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                groupHeaderBuilder: (BuildContext context, int section) {
                  return const Padding(
                    padding: EdgeInsets.all(0.0),
                    child: Text(
                      "",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                },

                scrollDirection: Axis.vertical,
                reverse: false,
                primary: true,
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemExtent: null,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                addSemanticIndexes: true,
                cacheExtent: 100,
                semanticChildCount: null,
                // },
              );
            },
          ),
        ));
  }
}
