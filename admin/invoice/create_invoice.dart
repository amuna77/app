import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:my_application/admin/invoice/dispaly_invoice.dart';
import 'package:my_application/admin/invoice/new_item.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:test_flutter_app24/admin/invoice/dispaly_invoice.dart';
import 'package:test_flutter_app24/admin/invoice/new_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradient_borders/gradient_borders.dart';

// Providers
class Providers {
  String id;
  String name;

  Providers({required this.id, required this.name});
  factory Providers.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Providers(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}

// Products
class Products {
  String id;
  String name;
  int quantity;
  int secureQuantity;

  Products(
      {required this.id,
      required this.name,
      required this.quantity,
      required this.secureQuantity});

  factory Products.romFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Products(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      secureQuantity: data['secureQuantity'] ?? 0,
    );
  }
}

class CreateInvoice extends StatefulWidget {
  const CreateInvoice({super.key});
  static const String routeName = '/create_invoice';

  @override
  State<CreateInvoice> createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends State<CreateInvoice> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? _provider;
  final List<Providers> providers = [];
  final List<Products> products = [];

  Set<String> selectedProductIds = {};
  Map<String, String> productTextFields = {};
  List<Map<String, String>> newItems = [];

  @override
  void initState() {
    super.initState();
    _fetchProviders();
    _fetchProduct();
  }

  // fetch providers
  Future<void> _fetchProviders() async {
    try {
      QuerySnapshot providerSnapshot =
          await firestore.collection('providers').get();

      List<Providers> fetchedProviders = [];

      providerSnapshot.docs.forEach((providerDoc) {
        var data = providerDoc.data() as Map<String, dynamic>;
        if (data.containsKey('name')) {
          var providerName = data['name'];
          if (providerName != null) {
            providers.add(Providers(
              id: providerDoc.id,
              name: providerName.toString(),
            ));
          }
        }
      });

      setState(() {
        providers.addAll(fetchedProviders);
      });

      print('Success fetching providers: $fetchedProviders');
    } catch (e) {
      print('Error fetching providers: $e');
    }
  }

  // fetch products

  Future<void> _fetchProduct() async {
    try {
      QuerySnapshot productSnapshot =
          await firestore.collection('products').get();

      print('Product Query Executed Successfully');
      print('Product Snapshot Size: ${productSnapshot.size}');

      List<Products> fetchedProducts = [];

      productSnapshot.docs.forEach((productDoc) {
        var data = productDoc.data() as Map<String, dynamic>;

        if (data.containsKey('name')) {
          var productName = data['name'];
          var quantity = data['quantity'];
          var secureQuantity = data['secureQuantity'];
          if (quantity == secureQuantity) {
            fetchedProducts.add(Products(
              id: productDoc.id,
              name: productName.toString(),
              quantity: quantity,
              secureQuantity: secureQuantity,
            ));
          }
        }
      });

      setState(() {
        products.addAll(fetchedProducts);
      });
      print('Success fetching products: $fetchedProducts');
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
        productTextFields.remove(productId);
      } else {
        selectedProductIds.add(productId);
        productTextFields[productId] = '';
      }
    });
  }

//add invoice

  void _addInvoice() async {
    try {
      if (_provider == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تحديد مزود'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      String providerName =
          providers.firstWhere((provider) => provider.id == _provider).name;
      int totalQuantity = 0;

      List<Map<String, dynamic>> selectedProducts = [];
      for (var productId in selectedProductIds) {
        String productName =
            products.firstWhere((product) => product.id == productId).name;
        String quantity = productTextFields[productId] ?? '0';

        int parsedQuantity = int.parse(quantity);
        if (parsedQuantity > 0) {
          selectedProducts.add({
            'productName': productName,
            'quantity': parsedQuantity,
          });
          totalQuantity += parsedQuantity;
        }
      }
      if (selectedProducts.isEmpty && totalQuantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الرجاء تحديد منتج واحد على الأقل وإدخال كمية صالحة'),
          backgroundColor: Colors.red,
        ));
        return;
      } else {
        DocumentReference save = await firestore.collection('invoices').add({
          'providerName': providerName,
          'providerId': _provider,
          'products': selectedProducts,
          'totalQuantity': totalQuantity,
          'timestamp': FieldValue.serverTimestamp(),
        });

        selectedProductIds.clear();
        productTextFields.clear();
        newItems.clear();
        print('Success adding invoice: ${save.id}');

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تمت إضافة الفاتورة بنجاح'),
          backgroundColor: Colors.green,
        ));
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(SwipeablePageRoute(
          canOnlySwipeFromEdge: true,
          builder: (BuildContext context) =>
              InvoiceDetailScreen(invoiceId: save.id),
        ));
      }
    } catch (e) {
      print('Error adding invoice: $e');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدث خطأ أثناء إضافة الفاتورة'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      reverse: true,
      dragStartBehavior: DragStartBehavior.start,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10.0),
        child: Form(
          canPop: true,
          child: Column(
            children: [
              Title(
                color: Colors.black,
                child: const SizedBox(
                  child: Text(
                    'إنشاء فاتورة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                    textWidthBasis: TextWidthBasis.parent,
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              DropdownButtonFormField(
                iconEnabledColor: Colors.black,
                isDense: true,
                isExpanded: false,
                borderRadius: BorderRadius.circular(12),
                value: _provider,
                onChanged: (value) {
                  setState(() {
                    _provider = value;
                  });
                },
                items: providers.map((provider) {
                  return DropdownMenuItem<String>(
                    value: provider.id,
                    child: Text(provider.name),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'اختر مورد',
                  labelStyle: TextStyle(color: Colors.black),
                  border: GradientOutlineInputBorder(
                    gradient: LinearGradient(colors: [
                      Colors.black,
                      Color.fromARGB(255, 15, 65, 106)
                    ]),
                    width: 2,
                  ),
                  focusedBorder: GradientOutlineInputBorder(
                      gradient:
                          LinearGradient(colors: [Colors.green, Colors.green]),
                      width: 2),
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    ':اختر العنصر',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        fontStyle: FontStyle.normal,
                        color: Color.fromARGB(255, 7, 34, 56)),
                    textAlign: TextAlign.end,
                  ),
                ),
              ]),
              const SizedBox(
                height: 5.0,
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = selectedProductIds.contains(product.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            _toggleProductSelection(product.id);
                          },
                          checkColor: Colors.green,
                          focusColor: Colors.green,
                          hoverColor: Colors.green,
                          activeColor: Colors.white,
                        ),
                        title: Text(product.name),
                        trailing: isSelected
                            ? SizedBox(
                                width: 130,
                                child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      productTextFields[product.id] = value;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'ادخل الكمية',
                                    labelStyle: TextStyle(color: Colors.black),
                                    border: GradientOutlineInputBorder(
                                      gradient: LinearGradient(colors: [
                                        Colors.black,
                                        Color.fromARGB(255, 15, 65, 106)
                                      ]),
                                      width: 2,
                                    ),
                                    focusedBorder: GradientOutlineInputBorder(
                                        gradient: LinearGradient(colors: [
                                          Colors.green,
                                          Colors.green
                                        ]),
                                        width: 2),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'الرجاء إدخال كمية المنتج';
                                    }
                                    return null;
                                  },
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30.0),
              const Text(
                '!إذا كنت تريد إضافة عنصر جديدأو ليس لديك عنصر، فانقر على الزر الأخير عنصر جديد',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.end,
              ),
              const SizedBox(
                height: 15,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () {
                    _navigateToAddNewItem();
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    width: 130,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        "عنصر جديد",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 30.0),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () {
                    _addInvoice();
                  },
                  child: Container(
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        "حفظ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddNewItem() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddNewItem()),
    );
  }
}
