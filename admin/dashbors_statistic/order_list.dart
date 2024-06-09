import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';

import 'package:group_list_view/group_list_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:intl/intl.dart';

// Orders
class OrdersList extends StatefulWidget {
  const OrdersList({super.key});

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.teal.shade400.withOpacity(.8),
          title: const Center(
            child: Text(
              'الطلبات',
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
                snapshot.data!.docs.where((doc) {
              var idLivreur = doc['id_livreur'];
              // var checkout = doc['checkout'];
              return idLivreur != null && idLivreur.isNotEmpty;
            }).toList();

            if (documents.isEmpty) {
              return const Center(
                child: Text('No orders available'),
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
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        Text(
                          (order.data() as Map<String, dynamic>)
                                  .containsKey('percentage')
                              ? ' discounted by percentage: ${(order.data() as Map<String, dynamic>)['percentage']} %'
                              : '',
                          style: TextStyle(
                            color: Color.fromARGB(255, 202, 194, 188),
                            fontWeight: FontWeight.bold,
                          ),
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
                          Navigator.of(context).push(SwipeablePageRoute(
                            canOnlySwipeFromEdge: true,
                            builder: (BuildContext context) =>
                                Details(cartId: order.id),
                          ));
                        },
                        child: const Text(
                          'View Details',
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            );
          },
        ),
      ),
    );
  }
}

// Cart
class Cart {
  final String id;
  final String clients;
  final String id_livreur;
  final double total_price;
  final String status;
  final Timestamp created_at;
  final Timestamp statusDate;

  Cart(
      {required this.id,
      required this.clients,
      required this.id_livreur,
      required this.total_price,
      required this.status,
      required this.created_at,
      required this.statusDate});

  factory Cart.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Cart(
      id: doc.id,
      clients: data['clients'] ?? '',
      id_livreur: data['id_livreur'] ?? '',
      total_price: data['total_price'] ?? 0.0,
      status: data['status'] ?? '',
      created_at: data['created_at'] ?? Timestamp.now(),
      statusDate: data['created_at'] ?? Timestamp.now(),
    );
  }
}

// Details

class Details extends StatefulWidget {
  final String cartId;

  const Details({required this.cartId});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late Stream<QuerySnapshot> _detailStream;
  final List<String> statuses = ['confirmed', 'cancelled', 'prepared'];
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _detailStream = FirebaseFirestore.instance
        .collection('details')
        .where('id_cart', isEqualTo: widget.cartId)
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
              'تفاصيل الطلب',
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
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('Cart')
                  .doc(widget.cartId)
                  .get(),
              builder: (context, cartSnapshot) {
                if (cartSnapshot.hasError) {
                  return Center(child: Text('Error: ${cartSnapshot.error}'));
                }

                if (cartSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor: const Color(0xFF1A1A3F),
                      rightDotColor: const Color(0xFFEA3799),
                      size: 50,
                    ),
                  );
                }

                if (!cartSnapshot.hasData || !cartSnapshot.data!.exists) {
                  return const Center(
                      child: Text('لم يتم العثور على سلة التسوق'));
                }

                if (cartSnapshot.connectionState == ConnectionState.none) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا يتوفر اتصال بالإنترنت'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }

                final cart = Cart.fromFirestore(cartSnapshot.data!);

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('livreurs')
                      .doc(cart.id_livreur)
                      .get(),
                  builder: (context, deliverySnapshot) {
                    if (deliverySnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${deliverySnapshot.error}'));
                    }

                    if (deliverySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: LoadingAnimationWidget.twistingDots(
                          leftDotColor: const Color(0xFF1A1A3F),
                          rightDotColor: const Color(0xFFEA3799),
                          size: 50,
                        ),
                      );
                    }

                    if (!deliverySnapshot.hasData ||
                        !deliverySnapshot.data!.exists) {
                      return const Center(
                          child: Text('لم يتم العثور على بيانات عامل التسليم'));
                    }

                    final deliveryData = deliverySnapshot.data!.data()!;

                    return FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('clients')
                          .doc(cart.clients)
                          .get(),
                      builder: (context, clientSnapshot) {
                        if (clientSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${clientSnapshot.error}'));
                        }

                        if (clientSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: LoadingAnimationWidget.twistingDots(
                              leftDotColor: const Color(0xFF1A1A3F),
                              rightDotColor: const Color(0xFFEA3799),
                              size: 50,
                            ),
                          );
                        }

                        if (!clientSnapshot.hasData ||
                            !clientSnapshot.data!.exists) {
                          return const Center(
                              child: Text('لم يتم العثور على بيانات العميل'));
                        }

                        final clientData = clientSnapshot.data!.data()!;

                        return SingleChildScrollView(
                          reverse: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15, width: 35),

                              Center(
                                child: Card(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(40),
                                      bottomRight: Radius.circular(40),
                                      topLeft: Radius.circular(40),
                                      topRight: Radius.circular(40),
                                    ),
                                    side: BorderSide(
                                      color: Colors.teal,
                                    ),
                                  ),
                                  borderOnForeground: true,
                                  surfaceTintColor: Colors.grey,
                                  child: Container(
                                    height: 200,
                                    width: 300,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        ListTile(
                                          title: Container(
                                            alignment: Alignment.centerRight,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                    '${clientData['surname']} ${deliveryData['name']}:العميل',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(height: 10),
                                                Text(
                                                    '${clientData['email']} :بريد إلكتروني',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(height: 10),
                                                Text(
                                                    '${clientData['phoneNumber']} :رقم الهاتف',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(height: 10),
                                                Center(
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      // textDirection: TextDirection.LTR,
                                                      children: [
                                                        Text(
                                                            (DateFormat('yyyy-MM-dd')
                                                                    .format(cart
                                                                        .created_at
                                                                        .toDate()))
                                                                .toString(),
                                                            textAlign:
                                                                TextAlign.end,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        const Text(':يوم',
                                                            textAlign:
                                                                TextAlign.end,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      ]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Center(
                                child: Card(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(40),
                                      bottomRight: Radius.circular(40),
                                      topLeft: Radius.circular(40),
                                      topRight: Radius.circular(40),
                                    ),
                                    side: BorderSide(color: Colors.teal),
                                  ),
                                  borderOnForeground: true,
                                  surfaceTintColor: Colors.grey,
                                  child: Container(
                                    height: 200,
                                    width: 300,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        ListTile(
                                          title: Container(
                                            // alignment: Alignment.topRight,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    '${deliveryData['surname']} ${deliveryData['name']}:عامل التوصيل',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(height: 10),
                                                Text(
                                                    '${deliveryData['email']} :بريد إلكتروني',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14)),
                                                const SizedBox(height: 10),
                                                Text(
                                                    '${deliveryData['phoneNumber']} :رقم الهاتف',
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              StreamBuilder<QuerySnapshot>(
                                stream: _detailStream,
                                builder: (context, detailsSnapshot) {
                                  if (detailsSnapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            'Error: ${detailsSnapshot.error}'));
                                  }
                                  if (detailsSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child:
                                          LoadingAnimationWidget.twistingDots(
                                        leftDotColor: const Color(0xFF1A1A3F),
                                        rightDotColor: const Color(0xFFEA3799),
                                        size: 50,
                                      ),
                                    );
                                  }
                                  if (!detailsSnapshot.hasData ||
                                      detailsSnapshot.data!.docs.isEmpty) {
                                    return const Center(
                                        child:
                                            Text('لم يتم العثور على التفاصيل'));
                                  }
                                  final List<QueryDocumentSnapshot> details =
                                      detailsSnapshot.data!.docs;
                                  return ListView.builder(
                                    reverse: true,
                                    shrinkWrap: true,
                                    itemCount: details.length,
                                    itemBuilder: (context, index) {
                                      final data = details[index].data()
                                          as Map<String, dynamic>;
                                      final String totalPrice =
                                          data['total_price']?.toString() ?? '';
                                      final String unitPrice =
                                          data['unit_price']?.toString() ?? '';
                                      final String quantity =
                                          data['quantite']?.toString() ?? '';
                                      final String? productId =
                                          data['id_produit'];

                                      return FutureBuilder<
                                          DocumentSnapshot<
                                              Map<String, dynamic>>>(
                                        future: FirebaseFirestore.instance
                                            .collection('products')
                                            .doc(productId)
                                            .get(),
                                        builder: (context, productSnapshot) {
                                          if (productSnapshot.hasError) {
                                            return Center(
                                                child: Text(
                                                    'خطأ: ${productSnapshot.error}'));
                                          }
                                          if (productSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child: LoadingAnimationWidget
                                                  .twistingDots(
                                                leftDotColor:
                                                    const Color(0xFF1A1A3F),
                                                rightDotColor:
                                                    const Color(0xFFEA3799),
                                                size: 50,
                                              ),
                                            );
                                          }
                                          if (!productSnapshot.hasData ||
                                              !productSnapshot.data!.exists) {
                                            return const Center(
                                                child: Text(
                                                    'لم يتم العثور على بيانات المنتج'));
                                          }
                                          final productData =
                                              productSnapshot.data!.data()!;
                                          return Card(
                                            // elevation: 25,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 5, horizontal: 20),
                                            surfaceTintColor: Colors.white,
                                            borderOnForeground: true,
                                            color: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(20),
                                                bottomRight:
                                                    Radius.circular(20),
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20),
                                              ),
                                              side: BorderSide(
                                                  color: Colors.black,
                                                  width: 2.0),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Image.network(
                                                    productData['image'],
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  const SizedBox(width: 15.0),
                                                  Column(
                                                    children: [
                                                      Text(
                                                          '${productData['name']}:اسم المنتج',
                                                          textAlign:
                                                              TextAlign.end,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black)),
                                                      Text('$quantity:الكمية',
                                                          textAlign:
                                                              TextAlign.end,
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      Text('السعر: $unitPrice',
                                                          textAlign:
                                                              TextAlign.end,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black)),
                                                      Text(
                                                          'السعر الإجمالي: $totalPrice',
                                                          textAlign:
                                                              TextAlign.end,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .green)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              // total price
                              Card(
                                // elevation: 25,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                surfaceTintColor: Colors.white,
                                borderOnForeground: true,
                                color: Colors.teal,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  side: BorderSide(
                                      color: Colors.black, width: 2.0),
                                ),
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  height: 60,
                                  child: Row(
                                    // textDirection: TextDirection.rtl,
                                    children: [
                                      const SizedBox(
                                        width: 60,
                                      ),
                                      Text(
                                        cart.total_price.toStringAsFixed(2),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Text(
                                        ':السعر الاجمالي',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Status
                              Center(
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  height: 70,
                                  child: Column(
                                    children: [
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 60,
                                            ),
                                            Text(
                                              cart.status,
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  fontSize: 20),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Text(
                                              ':حالة الطلب',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            ),
                                          ]),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                (DateFormat('yyyy-MM-dd hh:mm:ss')
                                                        .format(cart.created_at
                                                            .toDate()))
                                                    .toString(),
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            const Text(' :يوم',
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20)),
                                          ]),
                                    ],
                                  ),
                                ),
                              ),
                              // update status
                              Center(
                                child: Container(
                                  height: 120,
                                  width: 325,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      DropdownButtonFormField<String>(
                                        value: selectedStatus,
                                        items: statuses.map((status) {
                                          return DropdownMenuItem<String>(
                                            value: status,
                                            child: Text(status),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedStatus = value!;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                            labelText: 'حالة الطلب',
                                            border: GradientOutlineInputBorder(
                                              gradient: LinearGradient(colors: [
                                                Colors.teal,
                                                Colors.teal
                                              ]),
                                              width: 2,
                                            ),
                                            focusedBorder:
                                                GradientOutlineInputBorder(
                                                    gradient: LinearGradient(
                                                        colors: [
                                                          Colors.green,
                                                          Colors.green
                                                        ]),
                                                    width: 2)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  if (selectedStatus != null) {
                                    await updateStatusInFirestore(
                                        cartSnapshot.data!.reference,
                                        selectedStatus!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم تحديث حالة الطلب'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('يرجى تحديد حالة'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'تحديث الحالة',
                                  textAlign: TextAlign.right,
                                  // textDirection: TextDirection.rtl,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateStatusInFirestore(
      DocumentReference cartRef, String status) async {
    if (status != null) {
      final cartRef =
          FirebaseFirestore.instance.collection('Cart').doc(widget.cartId);
      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        await cartRef.update({
          'status': status,
          'statusDate': FieldValue.serverTimestamp(),
        });
        setState(() {
          selectedStatus = status;
        });
      } else {
        print('لم يتم العثور على مستند لمعرف سلة التسوق: ${widget.cartId}');
      }
    }
  }
}
