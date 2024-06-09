import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_application/admin/products/manage/firebase_service.dart';
import 'package:my_application/admin/products/manage/update_product_screen.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class ProductManage extends StatefulWidget {
  static const String routeName = '/products';

  const ProductManage({Key? key}) : super(key: key);

  @override
  _ProductManageState createState() => _ProductManageState();
}

class _ProductManageState extends State<ProductManage> {
  late Stream<QuerySnapshot> _productStream;
  FirebaseStorage storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _productStream =
        FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          SizedBox(
            height: 27,
          ),
          Title(
            color: Colors.black,
            child: const SizedBox(
              child: Text(
                'جدول بيانات المنتجات',
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
              stream: _productStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                    color: Colors.green,
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
                      columnSpacing: 18,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'الصورة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepOrange),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'الاسم',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepOrange),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'الكمية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepOrange),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'سعر',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepOrange),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepOrange),
                          ),
                        ),
                      ],
                      rows: documents.map((doc) {
                        final Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        final String name = data['name'] ?? '';
                        final String price = data['price']?.toString() ?? '';
                        final String quantity =
                            data['quantity']?.toString() ?? '';
                        final String imageURL = data['image'] ?? '';

                        final String id = doc.id;

                        return DataRow(
                          cells: [
                            DataCell(
                              snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const CircularProgressIndicator(
                                      color: Colors.green)
                                  : CircleAvatar(
                                      backgroundImage: NetworkImage(imageURL),
                                      radius: 30,
                                    ),
                            ),
                            DataCell(Text(name)),
                            DataCell(Text(quantity)),
                            DataCell(Text(price)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.amberAccent),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(SwipeablePageRoute(
                                        canOnlySwipeFromEdge: true,
                                        builder: (BuildContext context) =>
                                            EditProductPage(productId: id),
                                      ));
                                    },
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () {
                                        ProductServices services =
                                            ProductServices();
                                        services.deleteProduct(id);
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
                      dataRowColor: MaterialStateColor.resolveWith((states) {
                        return states.contains(MaterialState.selected)
                            ? Colors.transparent
                            : Colors.blueGrey.withOpacity(0.1);
                      }),
                      dataRowMaxHeight: 80,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
