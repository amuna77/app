import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:signature/signature.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';



class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  InvoiceDetailScreen({required this.invoiceId});

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  
  //  Signature
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 0.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // generate and save PDF
 Future<void> generateAndSavePDF(Invoice invoice, Map<String, dynamic> providerData, Map<String, dynamic> adminData) async {
    final doc = pw.Document();

    Uint8List? signatureBytes = await _controller.toPngBytes();
    try{
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [ 
            pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Supermarket name: Supermarket', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Admin: ${adminData['username']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Address: La zone 8', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('City: Mascara', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Email: ${adminData['email']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Phone Number: ${adminData['phone']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text('Provider Name: ${providerData['name']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Address: ${providerData['address']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('City: ${providerData['ville']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Email: ${providerData['providerEmail']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Phone Number: ${providerData['provderPhone']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text('Description:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                border: null,
                cellStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerStyle: const pw.TextStyle(color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
                headers: ['Reference', 'Description', 'Quantity'],
                data: invoice.products.map((product) {
                  int index = invoice.products.indexOf(product) + 1;
                  String productRef = 'PRD$index';
                  return [productRef, product['productName'], '${product['quantity']}'];
                }).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Total : ${invoice.total.toString()}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 16),
              pw.Text('Date: ${invoice.timestamp.toDate()}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text('Signature:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Container(
              height: 150,
              width: 200,
              child: pw.Image(pw.MemoryImage(signatureBytes!)),
            ),
            ]
          
          ),];
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());

     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Success saving PDF'),
        backgroundColor: Colors.green,  
      ),
    );


  } catch(e){
    print('Error generating or saving PDF: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error generating or saving PDF: $e'),
        backgroundColor: Colors.redAccent,  
      ),
    );

  }

}

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? uid = user?.uid;
  
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0), 
        child: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset(
                'assets/images/cyberlundi.png', 
                height: 50, 
                alignment: Alignment.topLeft,
              ),
              const SizedBox(width: 100),
              const Text(
                'Invoice',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 30, 
                  fontStyle: FontStyle.normal,
                ),
                textAlign: TextAlign.right,
              ),
            ],    
          ),
          backgroundColor: Colors.teal.shade400.withOpacity(.8),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(300),
              bottomRight: Radius.circular(0),
            ),
          ),
        ),
       ),

      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // get invoice 
        future: FirebaseFirestore.instance.collection('invoices').doc(widget.invoiceId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Center(
              child:LoadingAnimationWidget.twistingDots(
                leftDotColor: const Color(0xFF1A1A3F),
                rightDotColor: const Color(0xFFEA3799),
                size: 50,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Invoice not found'));
          }

          final invoice = Invoice.fromFirestore(snapshot.data!);

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('providers').doc(invoice.providerId).get(),
            builder: (context, providerSnapshot) {
              if (providerSnapshot.hasError) {
                return Center(child: Text('Error: ${providerSnapshot.error}'));
              }

              if (providerSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child:LoadingAnimationWidget.twistingDots(
                    leftDotColor: const Color(0xFF1A1A3F),
                    rightDotColor: const Color(0xFFEA3799),
                    size: 50,
                  ),
                );
              }

              if (!providerSnapshot.hasData || !providerSnapshot.data!.exists) {
                return Center(child: LoadingAnimationWidget.twistingDots(
                    leftDotColor: const Color(0xFF1A1A3F),
                    rightDotColor: const Color(0xFFEA3799),
                    size: 50,
                  ),
                );
              }

              final providerData = providerSnapshot.data!.data()!;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: fetchAdminData(uid!), // Fetch admin data here
                builder: (context, adminSnapshot) {
                if (adminSnapshot.hasError) {
                  return Center(child: Text('Error: ${adminSnapshot.error}'));
                }

                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child:LoadingAnimationWidget.twistingDots(
                      leftDotColor: const Color(0xFF1A1A3F),
                      rightDotColor: const Color(0xFFEA3799),
                      size: 50,
                    ),
                  );
                }

                if (!adminSnapshot.hasData || !adminSnapshot.data!.exists) {
                  return const Center(child: Text('Admin not found'));
                }
              
                final adminData = adminSnapshot.data!.data()!;


                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,                  
                      children: [
                        const Text('Supermarket name: Supermarket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                        Text('Admin: ${adminData['username']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                        const Text('Address: La zone 8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                        const Text('City: Mascara', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                        Text('Email: ${adminData['email']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                        Text('Phone Number: ${adminData['phone']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                        
                        const SizedBox(
                          height: 40,
                          width: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black, 
                              width: 2.0, 
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(8.0)), // Adjust the border radius for rounded corners
                          ),
                          child: SizedBox(
                            height: 150,
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Provider Name: ${providerData['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                                Text('Address: ${providerData['address']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                                Text('City: ${providerData['ville']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                                Text('Email: ${providerData['providerEmail']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                                Text('Phone Number: ${providerData['provderPhone']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.start),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        DataTable(
                          columnSpacing: 29,
                          columns: const [
                            DataColumn(label: Text('Reference', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text(' Description', style: TextStyle(color: Colors.white),)),
                            DataColumn(label: Text('Quantity', style: TextStyle(color: Colors.white),)),
                          ],
                          headingRowColor:  MaterialStateColor.resolveWith((states) {
                            return Colors.teal.shade400.withOpacity(.8);
                          }),
                          rows: invoice.products.map((product) {
                            int index = invoice.products.indexOf(product) + 1;
                            String productRef = 'PRD$index'; 
                            return DataRow(
                              cells: [
                                DataCell(Text(productRef)), 
                                DataCell(Text(product['productName'])),
                                DataCell(Text('${product['quantity']}')),
                              ],
                            );
                          }).toList(),
                          border: const TableBorder(
                            horizontalInside: BorderSide(
                              color: Color.fromARGB(255, 3, 35, 61),
                              width: 1.5,
                            ),
                            verticalInside:BorderSide(
                              color: Color.fromARGB(255, 3, 35, 61),
                              width: 1.5,
                            ),
                            top: BorderSide(
                              color: Color.fromARGB(255, 3, 35, 61),
                              width: 1.5,
                            ),
                            bottom: BorderSide(
                              color: Color.fromARGB(255, 3, 35, 61),
                              width: 1.5,
                            ),
                            right: BorderSide(
                              color: Color.fromARGB(255, 3, 35, 61),
                              width: 1.5,
                            ),
                            left: BorderSide(
                              color: Color.fromARGB(255, 3, 35, 61),
                              width: 1.5,
                            ),
                          ),                        
                          dataRowColor: MaterialStateColor.resolveWith((states) {
                            return states.contains(MaterialState.selected) ? Colors.blueGrey : Colors.white.withOpacity(0.1);
                          }),
                          dataTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                          sortColumnIndex: 1,
                          sortAscending: true,
                        ),
                        const SizedBox(height: 16),
                        Text('Total: ${invoice.total.toString()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),  
                        const SizedBox(height: 16),
                        Text('Date: ${invoice.timestamp.toDate()}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),                   
                        const Text(
                          'Signature:', 
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ), 
                          textAlign: TextAlign.start,                       
                        ),
                        Container(
                          alignment: Alignment.bottomRight,
                          height: 150,
                          width: 200,
                          decoration: const BoxDecoration(
                            border: BorderDirectional(
                              bottom: BorderSide(),
                              top: BorderSide(),
                              start: BorderSide(),
                              end: BorderSide(),
                            ),
                          ),
                          child: Signature(
                            controller: _controller,
                            height: 150,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),                   
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          User? user = FirebaseAuth.instance.currentUser;
          String? uid = user?.uid;

          DocumentSnapshot<Map<String, dynamic>> adminSnapshot = await fetchAdminData(uid!);
          Map<String, dynamic> adminData = adminSnapshot.data() ?? {};

          DocumentSnapshot<Map<String, dynamic>> invoiceSnapshot = await FirebaseFirestore.instance.collection('invoices').doc(widget.invoiceId).get();
          Invoice invoice = Invoice.fromFirestore(invoiceSnapshot);

          DocumentSnapshot<Map<String, dynamic>> providerSnapshot = await FirebaseFirestore.instance.collection('providers').doc(invoice.providerId).get();
          Map<String, dynamic> providerData = providerSnapshot.data() ?? {};

          generateAndSavePDF(
            invoice,
            providerData,
            adminData,
          );
        },

        backgroundColor: Colors.red,
        child: const Icon(
          CupertinoIcons.tray_arrow_down,
          color: Colors.white,
        ),
      ),

    );
  }
  // fetch admin data authenticate in count admin
  Future<DocumentSnapshot<Map<String, dynamic>>> fetchAdminData(String uid) async {
    return await FirebaseFirestore.instance.collection('admin').doc(uid).get();
  }

}

// Invoice

class Invoice {
  final String id;
  final String providerName;
  final String providerId;
  final List<Map<String, dynamic>> products;
  final int total;
  final Timestamp timestamp;

  Invoice({
    required this.id,
    required this.providerName,
    required this.products,
    required this.total,
    required this.timestamp,
    required this.providerId,
  });

  factory Invoice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Invoice(
      id: doc.id,
      providerName: data['providerName'] ?? '',
      providerId: data['providerId'] ?? '',
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      total: data['totalQuantity']?? 0,
      timestamp: data['timestamp'],
    );
  }
}

