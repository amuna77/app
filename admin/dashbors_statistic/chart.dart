import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter_new/flutter.dart' as charts;
import 'package:loading_animation_widget/loading_animation_widget.dart';


class ClientSignUpStatsScreen extends StatelessWidget {
   const ClientSignUpStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      
      body:FutureBuilder<List<SignUpData>>(
        future: _getClientSignUps(), 
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
          print('Snapshot data length: ${snapshot.data?.length}');
          snapshot.data?.forEach((data) {
            print('Month: ${data.month}, Count: ${data.count}');
          });

          final seriesList = _createSeriesList(snapshot.data!);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SignUpChart(
              seriesList,
              animate: true, 
            ),
          );
        },
      ),
    );
  }

 Future<List<SignUpData>> _getClientSignUps() async {
  List<SignUpData> signUpData = [];
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('clients').get();
    querySnapshot.docs.forEach((doc) {
      Timestamp timestamp = doc['date_inscription'];
      DateTime signupDate = timestamp.toDate();
      String month = '${signupDate.month}';
   
      bool found = false;
      for (SignUpData data in signUpData) {
        if (data.month == month) {
          data.count++;
          found = true;
          break;
        }
      }
      if (!found) {
        signUpData.add(SignUpData(month, 1));
      }
    });
  } catch (e) {
    print('Error fetching client sign-up data: $e');
  }
  return signUpData;
}

List<charts.Series<SignUpData, String>> _createSeriesList(List<SignUpData> data) {
  List<charts.Series<SignUpData, String>> seriesList = [];
  data.sort((a, b) => int.parse(a.month).compareTo(int.parse(b.month)));

  final monthNames = {
    '1': 'January',
    '2': 'February',
    '3': 'March',
    '4': 'April',
    '5': 'May',
    '6': 'June',
    '7': 'July',
    '8': 'August',
    '9': 'September',
    '10': 'October',
    '11': 'November',
    '12': 'December',
  };
  data.forEach((signUp) {
    final monthName = monthNames[signUp.month] ?? 'Unknown'; 
    seriesList.add(
      charts.Series<SignUpData, String>(
        id: signUp.month,
        domainFn: (SignUpData data, _) => monthName,
        measureFn: (SignUpData data, _) => data.count,
        data: [signUp],
        labelAccessorFn: (SignUpData data, _) => '$monthName: ${data.count}', 
         colorFn: (SignUpData data, _) => _getBarColor(data.month),
      ),
    );
  });

  return seriesList;
}
 charts.Color _getBarColor(String month) {
  // Define a color map for each month
  final colorMap = {
    '1': charts.MaterialPalette.blue.shadeDefault,
    '2': charts.MaterialPalette.green.shadeDefault,
    '3': charts.MaterialPalette.red.shadeDefault,
    '4': charts.MaterialPalette.purple.shadeDefault,
    '5': charts.MaterialPalette.yellow.shadeDefault,
    '6': charts.MaterialPalette.teal.shadeDefault,
    '7': charts.MaterialPalette.cyan.shadeDefault,
    '8': charts.MaterialPalette.indigo.shadeDefault,
    '9': charts.MaterialPalette.gray.shadeDefault,
    '10': charts.MaterialPalette.lime.shadeDefault,
    '11': charts.MaterialPalette.pink.shadeDefault,
    '12': charts.MaterialPalette.deepOrange.shadeDefault,
  };

  return colorMap[month] ?? charts.MaterialPalette.gray.shadeDefault; 
}


}

class SignUpData {
  final String month;
  int count;

  SignUpData(this.month, this.count);

  String get monthYear => '$month';
}

class SignUpChart extends StatelessWidget {
  final List<charts.Series<SignUpData, String>> seriesList;
  final bool animate;
  final double chartHeight;
  final double chartWidth;
  const SignUpChart(this.seriesList, {super.key, required this.animate, this.chartHeight = 200, 
    this.chartWidth = 300, });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: chartWidth,
      child: charts.BarChart(
        seriesList,
        animate: animate,
        vertical: true,
        primaryMeasureAxis: charts.NumericAxisSpec(
          renderSpec: const charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 10,
            ),
          ),
          tickFormatterSpec: charts.BasicNumericTickFormatterSpec((value) => '$value Sign-ups'), 
        ),
        domainAxis: const charts.OrdinalAxisSpec(
          renderSpec: charts.SmallTickRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 10,
            ),
          ),
          showAxisLine: true, 
        ),
      ),
    );
  }
}





