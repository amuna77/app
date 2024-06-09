// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class SearchScreen extends StatelessWidget {
//   final Future<QuerySnapshot>? clientQuery;
//   final Future<QuerySnapshot>? productQuery;
//   final Future<QuerySnapshot>? categoryQuery;

//   const SearchScreen({
//     super.key,
//     required this.clientQuery,
//     required this.productQuery,
//     required this.categoryQuery,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Clients',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         FutureBuilder<QuerySnapshot>(
//           future: clientQuery,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const CircularProgressIndicator();
//             } else if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Text('No clients found.');
//             } else {
//               return ListView(
//                 shrinkWrap: true,
//                 children: snapshot.data!.docs.map((doc) {
//                   return ListTile(
//                     title: Text(doc['username']),
//                   );
//                 }).toList(),
//               );
//             }
//           },
//         ),
//         const Text(
//           'Product',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         FutureBuilder<QuerySnapshot>(
//           future: productQuery,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const CircularProgressIndicator();
//             } else if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Text('No products found.');
//             } else {
//               return ListView(
//                 shrinkWrap: true,
//                 children: snapshot.data!.docs.map((doc) {
//                   return ListTile(
//                     title: Text(doc['name']),
//                   );
//                 }).toList(),
//               );
//             }
//           },
//         ),
//        const Text(
//           'Category',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         FutureBuilder<QuerySnapshot>(
//           future: categoryQuery,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const CircularProgressIndicator();
//             } else if (snapshot.hasError) {
//               return Text('Error: ${snapshot.error}');
//             } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Text('No categories found.');
//             } else {
//               return ListView(
//                 shrinkWrap: true,
//                 children: snapshot.data!.docs.map((doc) {
//                   return ListTile(
//                     title: Text(doc['name']),
//                   );
//                 }).toList(),
//               );
//             }
//           },
//         ),
        
//       ],
//     );
//   }
// }
