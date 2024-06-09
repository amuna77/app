import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_application/admin/categories/manage/firebase_service.dart';
import 'package:my_application/admin/categories/manage/update_category_screen.dart';

class CategoryManage extends StatefulWidget {
  static const String routeName = '/categories';

  const CategoryManage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CategoryManageState createState() => _CategoryManageState();
}

class _CategoryManageState extends State<CategoryManage> {
  late Stream<QuerySnapshot> _categoryStream;
  FirebaseStorage storage = FirebaseStorage.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late String id;

  @override
  void initState() {
    super.initState();
    _categoryStream =
        FirebaseFirestore.instance.collection('categories').snapshots();
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
              'جدول بيانات فئة المنتجات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
              textWidthBasis: TextWidthBasis.parent,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _categoryStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                color: Colors.green,
              );
            }

            final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              dragStartBehavior: DragStartBehavior.start,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(
                        label: Text(
                      'الصورة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange),
                    )),
                    DataColumn(
                        label: Text(
                      'الفئة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange),
                    )),
                    DataColumn(
                        label: Text(
                      'Action',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange),
                    )),
                  ],
                  rows: documents.map((doc) {
                    final Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    final String name = data['name'] ?? '';
                    final String imageURL = data['image'] ?? '';

                    final String id = doc.id;

                    return DataRow(
                      cells: [
                        DataCell(
                          snapshot.connectionState == ConnectionState.waiting
                              ? const CircularProgressIndicator(
                                  color: Colors.green,
                                )
                              : CircleAvatar(
                                  backgroundImage: NetworkImage(imageURL),
                                  radius: 30,
                                ),
                        ),
                        DataCell(Text(name)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.amberAccent,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EditCategoryPage(categoryId: id)),
                                );
                              },
                            ),
                            IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  CategorySrevices services =
                                      CategorySrevices();
                                  services.deleteCategory(id);
                                }),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                  sortColumnIndex: 1,
                  sortAscending: true,
                  horizontalMargin: 20,
                  dataTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  dataRowColor: MaterialStateColor.resolveWith((states) {
                    return states.contains(MaterialState.selected)
                        ? Colors.transparent
                        : Colors.blueGrey.withOpacity(0.1);
                  }),
                  dataRowMaxHeight: 80,
                  decoration: const BoxDecoration(
                    border: Border(
                      // left: BorderSide(),
                      // right: BorderSide(),
                      bottom: BorderSide(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}
