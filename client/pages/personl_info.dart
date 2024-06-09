import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PersonalInformationPage extends StatefulWidget {
  @override
  _PersonalInformationPageState createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  File? _image;
  String? _imageUrl;

  String? gender;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchUserInfo();
    });
  }

  Future<void> fetchUserInfo() async {
    try {
      String clientId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot documentSnapshot =
          await firestore.collection('clients').doc(clientId).get();
      if (documentSnapshot.exists) {
        setState(() {
          firstNameController.text = documentSnapshot.get('name') ?? '';
          lastNameController.text = documentSnapshot.get('surname') ?? '';
          emailController.text = documentSnapshot.get('email') ?? '';
          gender = documentSnapshot.get('gender') ?? '';
          _imageUrl = documentSnapshot.get('image');
        });
      }
    } catch (error) {
      print("Error fetching user information: $error");
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });

    // Call updateUserInformation with the selected image
    await updateUserInformation(image: _image);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'معلومات شخصية  ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Update Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? NetworkImage(_imageUrl!) as ImageProvider
                              : (gender == 'Male'
                                      ? AssetImage('assets/male.png')
                                      : AssetImage('assets/female.png'))
                                  as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: const Color.fromARGB(255, 9, 9, 9),
                        ),
                        onPressed: () {
                          // Update profile picture from gallery
                          _getImageFromGallery();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.0),

              // Personal Information Form
              Text(
                'المعلومات',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 11, 11, 11),
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الأول',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'اسم العائلة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 20.0),

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress, // Set email input type
                decoration: InputDecoration(
                  labelText: 'بريد إلكتروني',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 20.0),

              // Gender Dropdown
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'جنس',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 11, 11, 11),
                      ),
                    ),
                    DropdownButton<String>(
                      value: gender,
                      itemHeight: 60.0,
                      items: ['Male', 'Female'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(fontSize: 18.0),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          gender = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Save Button
              ElevatedButton(
                onPressed: () async {
                  // Update user information in Firestore
                  await updateUserInformation();
                },
                child: Text(
                  'تحديث المعلومات',
                  style: TextStyle(fontSize: 18.0),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color.fromARGB(255, 18, 16, 10),
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateUserInformation({
    File? image, // Assuming image is of type File and can be null
  }) async {
    try {
      String clientId = FirebaseAuth.instance.currentUser!.uid;
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get current user data from Firestore
      DocumentSnapshot userData =
          await firestore.collection('clients').doc(clientId).get();

      // Check if email is different or invalid
      if (emailController.text.trim() != userData.get('email') &&
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Veuillez entrer une adresse e-mail valide')));
        return;
      }

      // Upload profile picture to Firebase Storage if a new image is selected
      if (image != null) {
        String imageFileName = clientId + '_' + DateTime.now().toString();
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('profile_images/$imageFileName');
        UploadTask uploadTask = storageReference.putFile(image);
        TaskSnapshot taskSnapshot = await uploadTask;
        _imageUrl = await taskSnapshot.ref.getDownloadURL();
      } else if (_imageUrl == null || _imageUrl!.isEmpty) {
        _imageUrl = userData.get('image');
      }

      // Prepare data to update in Firestore
      Map<String, dynamic> updateData = {
        'email': emailController.text.trim(),
        'name': firstNameController.text.trim(),
        'surname': lastNameController.text.trim(),
        'gender': gender,
        'image': _imageUrl,
      };

      // Update user information in Firestore
      DocumentReference clientRef =
          firestore.collection('clients').doc(clientId);
      if (userData.exists) {
        await clientRef.update(updateData);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Informations mises à jour avec succès')));

        // Update information in the "reviews" collection
        QuerySnapshot reviewsSnapshot = await firestore
            .collection('reviews')
            .where('userID', isEqualTo: clientId)
            .get();
        reviewsSnapshot.docs.forEach((reviewDoc) async {
          await reviewDoc.reference.update({
            'userName': firstNameController.text.trim(),
            'userSurname': lastNameController.text.trim(),
            'userGender': gender,
            'userImage': _imageUrl,
          });
        });
      }

      DocumentSnapshot updatedUserData =
          await firestore.collection('clients').doc(clientId).get();
      if (userData.data().toString() == updatedUserData.data().toString()) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Les informations sont déjà à jour')));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Échec de la mise à jour des informations: $error')));
      print('Échec de la mise à jour des informations: $error');
    }
  }
}
