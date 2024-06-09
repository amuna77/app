import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? uid = user?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('admin').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;

        return Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(data?['profile_image'] ?? ''),
              radius: 30,
            ),
            const SizedBox(height: 15),
            Text(data?['username'] ?? '',style: const TextStyle(color: Colors.white),),
            const SizedBox(height: 5),
            Text(data?['email'] ?? '',style: const TextStyle(color: Colors.white)),
            // Add additional user information as needed
          ],
        );
      },
    );
  }
}

