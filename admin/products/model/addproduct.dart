import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:collection/collection.dart';


// Category
class Category{
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



class AddProductPage extends StatefulWidget {
  static const String routeName = '/add_product';

  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;

  final _globalKey = GlobalKey<FormState>();
  final _productnameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  late double _price;
  late int _quantity;
  late int _secureQuantity;

  File? _selectedImage;

  String? _category_id;
  final List<Category> _categories = [];
  
  @override
  void initState() {
    super.initState();
    _fetchCategories();
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



  
  // Upload Image
  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  
Future<void> _addProduct() async {
  if (_globalKey.currentState!.validate()) {
    if (_selectedImage != null) {
      final Reference refstorage = storage.ref().child(
          'product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await refstorage.putFile(_selectedImage!);
      final String downloadUrl = await refstorage.getDownloadURL();

      Category? selectedCategory = _categories.firstWhereOrNull((category) => category.id == _category_id);

      if (selectedCategory != null) {
        await firestore.collection('products').add({
          'category': selectedCategory.name, // Save category name instead of ID
          'brand': _brandController.text,
          'name': _productnameController.text.toLowerCase(),
          'detail': _descriptionController.text,
          'image': downloadUrl,
          'price': _price,
          'quantity': _quantity,
          'secureQuantity': _secureQuantity
        });

        _globalKey.currentState!.reset();
        _productnameController.clear();
        _descriptionController.clear();
        _brandController.clear();
        

        setState(() {
          _selectedImage = null;
         

        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('.تمت إضافة المنتج بنجاح'),
          backgroundColor: Colors.green,

          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على الفئة المحددة.'),
           backgroundColor: Colors.redAccent,

          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('.الرجاء اختيار صورة'),
          backgroundColor: Colors.redAccent,

        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          reverse: true,
          padding: const EdgeInsets.all(40.0),
          child: Form(
            key: _globalKey,
            child: Column(
              children: [
                Title(            
              color: Colors.black, 
              child: const SizedBox(               
                child:  Text('اضافة منتج',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                  textWidthBasis: TextWidthBasis.parent,
                ),
              ),          
            ),
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
                              gradient: LinearGradient(colors: [Colors.black, Color.fromARGB(255, 15, 65, 106)]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                              width: 2
                            ), 
                  ),
                ),
                const SizedBox(height: 20,),
                Row(
                  children: [
                    Expanded(
                      // flex:2,
                      child: TextFormField(
                        controller: _productnameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج',
                          hintText: 'أدخل اسم المنتج',
                          labelStyle: TextStyle(color: Colors.black),                            
                          border: GradientOutlineInputBorder(
                            gradient: LinearGradient(colors: [Colors.black, Color.fromARGB(255, 15, 65, 106)]),
                            width: 2,
                          ),
                          focusedBorder: GradientOutlineInputBorder(
                            gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                            width: 2
                          ), 
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
                      // flex: 1,
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'ماركة',
                          hintText: 'أدخل العلامة التجارية',
                          labelStyle: TextStyle(color: Colors.black),                            
                          border: GradientOutlineInputBorder(
                           gradient: LinearGradient(colors: [Colors.black, Color.fromARGB(255, 15, 65, 106)]),
                            width: 2,
                          ),
                          focusedBorder: GradientOutlineInputBorder(
                            gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                            width: 2
                          ), 
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
               
                const SizedBox(height: 20.0,),
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      labelStyle: TextStyle(color: Colors.black),                            
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.black, Color.fromARGB(255, 15, 65, 106)]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                              width: 2
                            ), 
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الوصف';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20,),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _price = double.tryParse(value) ?? 0.0;
                        },
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          labelStyle: TextStyle(color: Colors.black),                            
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.black, Color.fromARGB(255, 15, 65, 106)]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                              width: 2
                            ), 
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال السعر';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0,),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _quantity = int.tryParse(value) ?? 0;
                        },
                        decoration: const InputDecoration(
                          labelText: 'الكمية',
                          labelStyle: TextStyle(color: Colors.black),                            
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.black, Color.fromARGB(255, 15, 65, 106)]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                              width: 2
                            ), 
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كمية المنتج';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width:20),
                    Expanded(
                      child: TextFormField(
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _secureQuantity = int.tryParse(value) ?? 0;
                        },
                        decoration: const InputDecoration(
                          labelText: 'كمية آمنة',
                          labelStyle: TextStyle(color: Colors.black),                            
                            border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.black, Color.fromARGB(255, 15, 65, 106)]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                              width: 2
                            ), 
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كمية المنتج الآمنة';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0,),
                const Text(
                  "قم بتحميل صورة المنتج",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10,),
                GestureDetector(
                  onTap: () {
                    _uploadImage();
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null
                        ? const Icon(Icons.add_a_photo)
                        : Container(),
                  ),
                ),
                const SizedBox(height: 20.0,),
                GestureDetector(
                  onTap: () {
                    _addProduct();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    width: 150,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        "أضف منتج",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
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
    );
  }
}
