import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Future<List<Map<String, dynamic>>> fetchBestProductsData() async {
  DateTime now = DateTime.now();
  DateTime oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('details')
      .where('created_at', isGreaterThanOrEqualTo: oneMonthAgo)
      .get();

  Map<String, double> productTotalQuantities = {};
  for (var doc in querySnapshot.docs) {
    String productId = doc['id_produit'];
    double quantite = (doc['quantite'] is int)
        ? (doc['quantite'] as int).toDouble()
        : doc['quantite'];
    if (productTotalQuantities.containsKey(productId)) {
      productTotalQuantities[productId] =
          productTotalQuantities[productId]! + quantite;
    } else {
      productTotalQuantities[productId] = quantite;
    }
  }

  List<Map<String, dynamic>> bestProductsData = [];
  for (var entry in productTotalQuantities.entries) {
    DocumentSnapshot productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(entry.key)
        .get();

    if (productDoc.exists) {
      String productName = productDoc['name'];
      bestProductsData.add({
        'productId': entry.key,
        'productName': productName,
        'total_quantite': entry.value,
      });
    }
  }

  bestProductsData
      .sort((a, b) => b['total_quantite'].compareTo(a['total_quantite']));
  bestProductsData = bestProductsData.take(5).toList();

  return bestProductsData;
}

class BestProductsChart extends StatelessWidget {
  final List<Color> customColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchBestProductsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.twistingDots(
              leftDotColor: const Color(0xFF1A1A3F),
              rightDotColor: const Color(0xFFEA3799),
              size: 50,
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        List<Map<String, dynamic>> bestProductsData =
            snapshot.data as List<Map<String, dynamic>>;

        return PieChart(PieChartData(
          sections: bestProductsData
              .map((product) => PieChartSectionData(
                    value: product['total_quantite'].toDouble(),
                    title: product['productName'],
                    color: customColors[bestProductsData.indexOf(product) %
                        customColors.length],
                  ))
              .toList(),
          sectionsSpace: 0,
          centerSpaceRadius: 20,
        ));
      },
    );
  }
}

class BestProductsChartScreen extends StatelessWidget {
  const BestProductsChartScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Best Products Sold',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BestProductsChart(),
            ),
          ],
        ),
      ),
    );
  }
}
