import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:my_application/admin/invoice/add_promotion.dart';

import 'package:swipeable_page_route/swipeable_page_route.dart';

// Category
class Category {
  String id;
  String name;
  Category({required this.id, required this.name});
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}

class EditProductPage extends StatefulWidget {
  static const String routeName = '/add_product';

  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;

  final _globalKey = GlobalKey<FormState>();
  final _productnameController = TextEditingController();
  final _productbrandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  final _secureQuantity = TextEditingController();
  final _quantitydetails = TextEditingController();
  final _purchasePrice = TextEditingController();

  DateTime? date_expiration;
  DateTime? date_purchase;

  File? _selectedImage;
  String? _imageUrl;

  String? _category_id;
  List<Category> _categories = [];

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().millisecondsSinceEpoch}');
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);

      try {
        await uploadTask.whenComplete(() async {
          _imageUrl = await storageRef.getDownloadURL();
        });

        setState(() {
          _imageUrl = _imageUrl;
        });
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  // date expiration
  Future<void> _selectDateExpiration(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(DateTime.now().year + 10));
    if (pickedDate != null && pickedDate != date_expiration) {
      setState(() {
        date_expiration = pickedDate;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    fetchProductData();
  }

  // fetch category
  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot categoriesSnapshot =
          await firestore.collection('categories').get();

      List<Category> categories = [];

      categoriesSnapshot.docs.forEach((categoryDoc) {
        var data = categoryDoc.data() as Map<String, dynamic>;
        if (data.containsKey('name')) {
          var categoryName = data['name'];
          if (categoryName != null) {
            categories.add(Category(
              id: categoryDoc.id,
              name: categoryName.toString(),
            ));
          }
        }
      });

      setState(() {
        _categories.addAll(categories);
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // fetch product data
  Future<void> fetchProductData() async {
    try {
      final DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (productSnapshot.exists) {
        final productData = productSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _productbrandController.text = productData['brand'] ?? '';
          _productnameController.text = productData['name'] ?? '';
          // _category_id = productData['category'] is List ? productData['category'][0] : productData['category'];
          _descriptionController.text = productData['detail'] ?? '';
          _price.text = productData['price']?.toString() ?? '';
          _quantity.text = productData['quantity']?.toString() ?? '';
          _secureQuantity.text =
              productData['secureQuantity']?.toString() ?? '';
          _imageUrl = _imageUrl ?? productData['image'];
        });
      } else {
        print('Product document does not exist for ID: ${widget.productId}');
      }
    } catch (e) {
      print('Error fetching product data: $e');
    }
  }

// update product
  Future<String?> updateProducts() async {
    try {
      if (_imageUrl == null && _selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
        return null;
      }

      // Ensure the selected category is not null
      if (_category_id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
        return null;
      }

      Category? selectedCategory = _categories.firstWhere(
        (category) => category.id == _category_id,
      );

      String productId = widget.productId;
      Map<String, dynamic> newData = {
        'name': _productnameController.text,
        'brand': _productbrandController.text,
        'detail': _descriptionController.text,
        'secureQuantity': int.parse(_secureQuantity.text),
        'category': selectedCategory.name,
        'price': double.parse(_price.text),
        'image': _imageUrl,
      };

      double purchasePrice = double.parse(_purchasePrice.text);

      // detial Product quantity
      int additionalQuantity = int.tryParse(_quantitydetails.text) ?? 0;

      double totalPrice = purchasePrice * additionalQuantity;

      if (additionalQuantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب أن تكون الكمية عددًا صحيحًا موجبًا.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
        return null;
      }

      if (purchasePrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب أن تكون السعر عددًا موجبًا.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
        return null;
      }

      await firestore.collection('products').doc(productId).update(newData);

      DocumentReference productRef =
          firestore.collection('products').doc(productId);
      DocumentSnapshot productSnapshot = await productRef.get();

      if (productSnapshot.exists) {
        var data = productSnapshot.data() as Map<String, dynamic>;
        int currentQuantity = data['quantity'] ?? 0;
        await productRef
            .update({'quantity': currentQuantity + additionalQuantity});
        print('Product updated successfully ID: $productId');

        if (additionalQuantity > 0 && purchasePrice > 0) {
          DocumentReference ligneFacture =
              await firestore.collection('detailProduct').add({
            'productId': widget.productId,
            'quantity': additionalQuantity,
            'purchasePrice': purchasePrice,
            'totalPrice': totalPrice,
            'purchaseDate': FieldValue.serverTimestamp(),
            'expirationDate': date_expiration,
          });
          print('Ligne Facture added successfully: ${ligneFacture.id}');
          print('Total price is : $totalPrice');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المنتج بنجاح.'),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );

        _quantitydetails.clear();
        _purchasePrice.clear();
        setState(() {
          date_expiration = null;
        });

        return productId;
      } else {
        print('Product not found with ID: $productId');
        return null;
      }
    } catch (e) {
      print('Error updating products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تحديث المنتج.'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: AppBar(
              backgroundColor: Colors.teal.shade400.withOpacity(.8),
              title: const Center(
                child: Text(
                  'تحديث المنتج',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
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
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _globalKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _category_id,
                    onChanged: (value) {
                      setState(() {
                        _category_id = value!;
                      });
                    },
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'اختر الفئة',
                      labelStyle: TextStyle(color: Colors.black),
                      border: GradientOutlineInputBorder(
                        gradient: LinearGradient(colors: [
                          Colors.black,
                          Color.fromARGB(255, 15, 65, 106)
                        ]),
                        width: 2,
                      ),
                      focusedBorder: GradientOutlineInputBorder(
                          gradient: LinearGradient(
                              colors: [Colors.green, Colors.green]),
                          width: 2),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        // flex:1,
                        child: TextFormField(
                          controller: _productnameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المنتج',
                            hintText: 'أدخل اسم المنتج',
                            labelStyle: TextStyle(color: Colors.black),
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [
                                Colors.black,
                                Color.fromARGB(255, 15, 65, 106)
                              ]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                                gradient: LinearGradient(
                                    colors: [Colors.green, Colors.green]),
                                width: 2),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال اسم المنتج';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        // flex:1,
                        child: TextFormField(
                          controller: _productbrandController,
                          decoration: const InputDecoration(
                            labelText: 'ماركة',
                            hintText: 'أدخل العلامة التجارية للمنتج',
                            labelStyle: TextStyle(color: Colors.black),
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [
                                Colors.black,
                                Color.fromARGB(255, 15, 65, 106)
                              ]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                                gradient: LinearGradient(
                                    colors: [Colors.green, Colors.green]),
                                width: 2),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال العلامة التجارية للمنتج';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        labelStyle: TextStyle(color: Colors.black),
                        border: GradientOutlineInputBorder(
                          gradient: LinearGradient(colors: [
                            Colors.black,
                            Color.fromARGB(255, 15, 65, 106)
                          ]),
                          width: 2,
                        ),
                        focusedBorder: GradientOutlineInputBorder(
                            gradient: LinearGradient(
                                colors: [Colors.green, Colors.green]),
                            width: 2),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال وصف للمنتج';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          controller: _price,
                          decoration: const InputDecoration(
                            labelText: 'سعر البيع',
                            labelStyle: TextStyle(color: Colors.black),
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [
                                Colors.black,
                                Color.fromARGB(255, 15, 65, 106)
                              ]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                                gradient: LinearGradient(
                                    colors: [Colors.green, Colors.green]),
                                width: 2),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال سعر البيع';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          keyboardType: TextInputType.number,
                          controller: _quantitydetails,
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                            labelStyle: TextStyle(color: Colors.black),
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [
                                Colors.black,
                                Color.fromARGB(255, 15, 65, 106)
                              ]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                                gradient: LinearGradient(
                                    colors: [Colors.green, Colors.green]),
                                width: 2),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال كمية المنتج';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          keyboardType: TextInputType.number,
                          controller: _secureQuantity,
                          decoration: const InputDecoration(
                            labelText: 'الكمية الآمنة',
                            labelStyle: TextStyle(color: Colors.black),
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black,
                                  Color.fromARGB(255, 15, 65, 106)
                                ],
                              ),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(
                                  colors: [Colors.green, Colors.green]),
                              width: 2,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال كمية آمنة';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          controller: _purchasePrice,
                          decoration: const InputDecoration(
                            labelText: 'سعر الشراء',
                            labelStyle: TextStyle(color: Colors.black),
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [
                                Colors.black,
                                Color.fromARGB(255, 15, 65, 106)
                              ]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                                gradient: LinearGradient(
                                    colors: [Colors.green, Colors.green]),
                                width: 2),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال سعر الشراء';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    child: InkWell(
                      onTap: () {
                        _selectDateExpiration(context);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ انتهاء الصلاحية',
                          border: GradientOutlineInputBorder(
                            gradient: LinearGradient(colors: [
                              Colors.black,
                              Color.fromARGB(255, 15, 65, 106)
                            ]),
                            width: 2,
                          ),
                          focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(
                                  colors: [Colors.green, Colors.green]),
                              width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            Text(date_expiration == null
                                ? 'حدد تاريخ '
                                : '${date_expiration!.day}/${date_expiration!.month}/${date_expiration!.year}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  const Text(
                    "قم بتحميل صورة المنتج",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      _uploadImage().then((_) {
                        setState(() {});
                      });
                    },
                    child: Column(
                      children: [
                        if (_selectedImage != null)
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: FileImage(_selectedImage!),
                          ),
                        if (_imageUrl != null && _selectedImage == null)
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: NetworkImage(_imageUrl!),
                          ),
                        if (_selectedImage == null && _imageUrl == null)
                          const CircleAvatar(
                            radius: 80,
                            child: Icon(Icons.add_a_photo),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  GestureDetector(
                    onTap: () async {
                      String? productId = await updateProducts();
                      if (productId != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تخديث المنتج بنجاح'),
                            duration: Duration(seconds: 4),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _addPromotionDialogue(productId);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.lightGreen[700],
                        borderRadius: BorderRadius.circular(10),
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
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addPromotionDialogue(String? productId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('إضافة الترويج'),
            content: const Text('هل تريد إضافة ترويج لهذا المنتج؟ '),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('الغاء'),
              ),
              if (productId != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToAddPromotion(productId);
                  },
                  child: const Text('إضافة'),
                ),
            ],
          );
        });
  }

  // navigate to add promotion
  void _navigateToAddPromotion(String productId) {
    Navigator.of(context).push(SwipeablePageRoute(
      canOnlySwipeFromEdge: true,
      builder: (BuildContext context) => AddPromotion(productId: productId),
    ));
  }
}
