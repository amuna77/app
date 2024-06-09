import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';





class Reduction extends StatefulWidget {
  static const String routeName = '/reduction';

  const Reduction({Key? key}) : super(key: key);

  @override
  State<Reduction> createState() => _ReductionState();
}

class _ReductionState extends State<Reduction> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _percentageController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _globalKey = GlobalKey<FormState>();

  Future<void> _addReduction(double percentage, double discountedPrice) async {
    if (percentage <= 0 || percentage > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('! يجب أن تكون النسبة بين 0 و100'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (discountedPrice <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('السعر يجب أن يكزن أكبر من 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      DocumentReference redc = await firestore.collection('reduction').add({
        'percentage': percentage,
        'discountedPrice': discountedPrice,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Successfully adding reduction: ${redc.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة التخفيض بنجاح'),
        backgroundColor: Colors.green,
      ),
      );

    } catch (error) {
      print('Error adding reduction: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return    Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.teal.shade400.withOpacity(.8),
          title: const Center(
            child: Text(
              'اضافة تخفيض',
              // textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 35),
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
              const SizedBox(height: 50),
              SizedBox(
                width: 250,
                child: TextFormField(
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
              controller: _percentageController,
              keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(
                            FontAwesomeIcons.percent,
                          ),
                    labelText: 'نسبة التخفيض',
                    hintText: 'ادخل النسبة',
                    labelStyle: TextStyle(color: Colors.black),
                    border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.black, Colors.black]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                              width: 2
                            ),

                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء ادخال النسبة';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height:20.0),
              SizedBox(
                width: 250,
                child: TextFormField(
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              controller: _discountedPriceController,
              keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(
                      FontAwesomeIcons.arrowTrendDown,
                    ),
                    labelText: 'السعر المحدد',
                    hintText: 'ادخل السعر',
                    labelStyle: TextStyle(color: Colors.black),
                    border: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.black, Colors.black]),
                              width: 2,
                            ),
                            focusedBorder: GradientOutlineInputBorder(
                              gradient: LinearGradient(colors: [Colors.green, Colors.green]),
                              width: 2
                            ),

                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء ادخال السعر';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 30.0),
              GestureDetector(
                onTap: () {
                  if (_globalKey.currentState?.validate() ?? false) {
                    _addReduction(
                      double.tryParse(_percentageController.text) ?? 0.0,
                      double.tryParse(_discountedPriceController.text) ?? 0.0,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  width: 160,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "اضف تخفيض",
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
    );
  }
}
















class ListReduction extends StatefulWidget {
  static const String routeName = '/reduction_screen';

  const ListReduction({super.key});

  @override
  State<ListReduction> createState() => _ListReductionState();
}

class _ListReductionState extends State<ListReduction> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _deliveryStream;

  late String id;

  @override
  void initState() {
    super.initState();
    _deliveryStream = FirebaseFirestore.instance.collection('reduction')
    .orderBy('timestamp', descending: true)
    .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      
     body: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child:  Column(
        children :[
          SizedBox(height: 20,),
          Title(            
              color: Colors.black, 
              child: const SizedBox(               
                child:  Text('التخفيض',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                  textWidthBasis: TextWidthBasis.parent,
                ),
              ),          
            ), 
          Container(
            
            child: StreamBuilder<QuerySnapshot>(
              stream: _deliveryStream,
              builder : (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor: const Color(0xFF1A1A3F),
                      rightDotColor: const Color(0xFFEA3799),
                      size: 50,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.none) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا يتوفر اتصال بالإنترنت'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.redAccent,
                    ),
                  );                    
                }

                final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;                
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child:SingleChildScrollView(
                    dragStartBehavior:   DragStartBehavior.start,
                    scrollDirection: Axis.vertical,
                    child : DataTable(
                     columnSpacing: 74,                     
                    columns: const [
                      DataColumn(
                        label: Text(
                          'السعر',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange),
                        ),
                      ),
                      
                      DataColumn(
                        label: Text(
                          'النسبة',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Action',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange),
                        ),
                      ),
                    ],
                    rows: documents.map((doc) {
                      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      final String price = data['discountedPrice']?.toString() ?? '';
                     final String percontage = data['percentage']?.toString() ?? '';
                

                      final String id = doc.id;


                      return DataRow(
                        cells: [
                          
                          DataCell(Text(price )),
                          DataCell(Row(
                            children: [
                            Text(percontage),
                            const SizedBox(width: 2,),
                            const Icon(FontAwesomeIcons.percent, color: Colors.green,),
                            ],)
                          ),                          DataCell(
                            Row(
                        children: [
                          
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: ()async {
                                try{
                                  CollectionReference products = await firestore.collection('reduction');

                                  await products.doc(id).delete();

                                  print('reduction deleted succesfully');

                                }catch(e) {

                                  print('Error deleting provider: $e');
                                }
                              }),
                        ],
                      ),
                          ),
                        ],
                      );
                    }).toList(),
                    
              sortColumnIndex: 1,
              sortAscending: true,
              horizontalMargin: 20,
              dataTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              dataRowColor: MaterialStateColor.resolveWith((states) {
                return states.contains(MaterialState.selected) ? Colors.transparent : Colors.blueGrey.withOpacity(0.1);
              }),
              dataRowMaxHeight: 80,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(),
                ),
              )))
                );
              },
            )
          ),
        ]
    )),
    floatingActionButton: FloatingActionButton(onPressed: () {
      Navigator.of(context).push(SwipeablePageRoute(
        canOnlySwipeFromEdge: true,
        builder: (BuildContext context) =>
          const Reduction(),
      ));     
    },
        backgroundColor: Colors.teal,
     child: const Icon(Icons.add),
    ),
    );
  }
}