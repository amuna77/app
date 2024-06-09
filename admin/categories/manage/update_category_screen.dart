import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_application/admin/categories/manage/firebase_service.dart';

class EditCategoryPage extends StatefulWidget {
  final String categoryId;

  const EditCategoryPage({super.key, required this.categoryId});

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  final _globalKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  String? _imageUrl;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('category_images')
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

  @override
  void initState() {
    super.initState();
    fetchCategoryData();
  }

  Future<void> fetchCategoryData() async {
    try {
      final DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .get();

      if (categorySnapshot.exists) {
        final categoryData = categorySnapshot.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = categoryData['name'] ?? '';
          _descriptionController.text = categoryData['detail'] ?? '';
          _imageUrl = categoryData['image'];
        });
      }
    } catch (error) {
      print('Error fetching category data: $error');
    }
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
              'تحديث المنتج',
              textAlign: TextAlign.center,
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
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Form(
            key: _globalKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: 250,
                  child: TextFormField(
                    dragStartBehavior: DragStartBehavior.down,
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الفئة',
                      hintText: 'ادخل اسم الفئة',
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
                        return 'الرجاء ادخال اسم الفئة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                SizedBox(
                  width: 250,
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
                        return 'الرجائ ادخال الوصف';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 30.0,
                ),
                const Text(
                  "قم بتحميل صورة الفئة",
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
                  onTap: () {
                    if (_imageUrl == null && _selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(' الرجاء تحميل الصورة'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    Map<String, dynamic> newData = {
                      'name': _nameController.text,
                      'detail': _descriptionController.text,
                      'image': _imageUrl,
                    };
                    CategorySrevices()
                        .updateCategory(widget.categoryId, newData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم تحديث الفئة بنجاح.'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.green),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green[700],
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
    );
  }
}
