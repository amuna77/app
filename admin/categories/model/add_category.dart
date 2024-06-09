import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:image_picker/image_picker.dart';




class AddCategoryPage extends StatefulWidget {
  static const String routeName = '/add_category_screen';

  const AddCategoryPage({super.key});
  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;

  final _globalKey = GlobalKey<FormState>();
  final _categorynameController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;

  //  upload image
  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _addCategory() async {
    if (_globalKey.currentState!.validate()) {
      if (_selectedImage != null) {
        final Reference refstorage = storage.ref().child('category_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await refstorage.putFile(_selectedImage!);
        final String downloadUrl = await refstorage.getDownloadURL();

        await firestore.collection('categories').add({
          'name': _categorynameController.text.toLowerCase(),
          'detail': _descriptionController.text,
          'image': downloadUrl
        });

        _globalKey.currentState!.reset();
        _categorynameController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedImage = null;
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category added successfully.'),
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تحديد الصورة'),
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return  SingleChildScrollView(
            reverse: true,
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _globalKey,
              child: Column(
                children: [
                    Title(            
              color: Colors.black, 
              child: const SizedBox(               
                child:  Text('اضافة فئة المنتج',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                  textWidthBasis: TextWidthBasis.parent,
                ),
              ),          
            ),
            SizedBox(
              height:20,
            ),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _categorynameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الفئة',
                        hintText: 'ادخل الفئة',
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
                          return 'الرجاء الدحال الفئة';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0,),
                  SizedBox(
                    width: 250,
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
                          return 'الرجاء ادخال الوصف';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 30.0,),
                  const Text(
                    "قم بتحميل صورة للفئة",
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
                      radius: 80,
                      backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.add_a_photo)
                          : Container(),
                    ),
                  ),
                  const SizedBox(height: 30.0,),
                  GestureDetector(
                    onTap: () {
                      _addCategory();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          "اضف فئة",
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
    );
  }
}
