import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TotalPriceSalesMonthly extends StatefulWidget {
  const TotalPriceSalesMonthly({super.key});

  @override
  State<TotalPriceSalesMonthly> createState() => _TotalPriceSalesMonthlyState();
}

class _TotalPriceSalesMonthlyState extends State<TotalPriceSalesMonthly> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  double totalMonthlyPrice = 0.0;
  double totalMonthlyPriceofCart = 0.0;
  Color textColor = Colors.black;
  IconData iconData = Icons.horizontal_rule;

  @override
  void initState() {
    super.initState();
    calculateTotalMonthlyPricePurchased();
    calculateTotalMonthlyPriceOfCart();
  }

  // Calculate Total Monthly Price Purchased
  Future<void> calculateTotalMonthlyPricePurchased() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(seconds: 1));

    QuerySnapshot querySnapshot = await firestore.collection('detailProduct')
        .where('purchaseDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('purchaseDate', isLessThanOrEqualTo: endOfMonth)
        .get();

    double totalPrice = 0.0;
    querySnapshot.docs.forEach((doc) {
      totalPrice += doc['totalPrice'];
    });

    setState(() {
      totalMonthlyPrice = totalPrice;
      updateTextColorAndIcon(); // Ensure comparison logic is executed after setting the total price
    });

    print('Total price of products purchased is: $totalMonthlyPrice');
  }

  // Calculate Total Monthly Price Sold
  Future<void> calculateTotalMonthlyPriceOfCart() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));

    QuerySnapshot querySnapshot = await firestore.collection('Cart')
        .where('created_at', isGreaterThanOrEqualTo: startOfMonth)
        .where('created_at', isLessThanOrEqualTo: endOfMonth)
        .get();

    double totalPrice = 0.0;
    querySnapshot.docs.forEach((doc) {
      totalPrice += doc['total_price'];
    });

    setState(() {
      totalMonthlyPriceofCart = totalPrice;
      updateTextColorAndIcon(); // Ensure comparison logic is executed after setting the total price of cart
    });

    print('Total price of products sold is: $totalMonthlyPriceofCart');
  }

  // Compare totals and update text color and icon
  void updateTextColorAndIcon() {
    setState(() {
      if (totalMonthlyPrice > totalMonthlyPriceofCart) {
        textColor = Colors.red;
        iconData = Icons.arrow_downward;
      } else if (totalMonthlyPrice < totalMonthlyPriceofCart) {
        textColor = Colors.green;
        iconData = Icons.arrow_upward;
      } else {
        textColor = Colors.black;
        iconData = Icons.horizontal_rule;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('إجمالي المشتريات',
                   style:  TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black,
                      fontSize: 20
                    )
                  ),
                  const SizedBox(height: 3.0),
                  Text('DA${totalMonthlyPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black,
                      fontSize: 15
                    )
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('إجمالي المبيعات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black,
                      fontSize: 20                 
                   )
                  ),
                  
                  const SizedBox(height: 3.0),

                  Text('DA${totalMonthlyPriceofCart.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold, color: textColor,
                    )
                  ),
                  // const SizedBox(width: 4.0),
                  // Icon(iconData, color: textColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
