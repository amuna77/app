import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';




class AddPromotion extends StatefulWidget {
 
  final String? productId;

  const AddPromotion({super.key, required this.productId});

  @override
  State<AddPromotion> createState() => _AddPromotionState();
}

class _AddPromotionState extends State<AddPromotion> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _percentageController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();

  // ignore: non_constant_identifier_names
  void _CalculeDiscount() {
  double percentage = double.tryParse(_percentageController.text) ?? 0.0;
  double sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
  if (percentage >0 || percentage <= 100) {    
  double discountedPrice = sellingPrice - (sellingPrice * (percentage / 100));  
  if (discountedPrice >= 0) {
    setState(() {
      _discountedPriceController.text = discountedPrice.toString();
    });
  } else {
    setState(() {
      _discountedPriceController.text = '0.0'; 
    });
  }}
}
  Future<void> _addPromotion(
    String productId,
    double sellingPrice,
    double percentage,
    double discountedPrice,
  ) async {
    if (percentage <= 0 || percentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Percentage must be between 0 and 100.')),
      );
      return; 
    }
    try {
      DocumentReference promo =  await firestore.collection('promotions').add({
        'productId': productId,
        'sellingPrice': sellingPrice,
        'percentage': percentage,
        'discountedPrice': discountedPrice,
        'timestamp': FieldValue.serverTimestamp(), 
      });
        print('promotion added successfully: ${promo.id}');
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promotion added successfully.'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.green,
          
        ),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (error) {
      print('Error adding promotion: $error');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error adding promotion !'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.redAccent,
          
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Promotion Details'),
      ),
      body: SingleChildScrollView(
        reverse: true,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
              ],
              controller: _percentageController,
              keyboardType: TextInputType.number,
              decoration:  const InputDecoration(
                labelText: 'Percentage',
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
                  return 'Please enter percentage';
                }
                return null;
              },
            ),
            TextFormField(
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
              ],
              controller: _sellingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price',
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
            ElevatedButton(
              onPressed: _CalculeDiscount,
              child: const Text('Calculate Discounted Price'),
            ),
            const SizedBox(height: 20),
            Text('Discounted Price: ${_discountedPriceController.text}'),
            ElevatedButton(
              onPressed: () {
                 _addPromotion(
                  widget.productId!,
                  double.tryParse(_sellingPriceController.text) ?? 0.0,
                  double.tryParse(_percentageController.text) ?? 0.0,
                  double.tryParse(_discountedPriceController.text) ?? 0.0,
                );

                Navigator.pop(context);
              },
              child: const Text('Add Promotion'),
            ),
          ],
        ),
      ),
    );
  }
}