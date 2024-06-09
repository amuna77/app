import 'package:flutter/material.dart';

class Appwidget {
  static TextStyle boldTextFeilsStyle() {
    return TextStyle(
        color: Colors.black,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins');
  }

  static TextStyle HeadlineTextFeilsStyle() {
    return TextStyle(
        color: Colors.black,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins');
  }

  static TextStyle LightTextFeilsStyle() {
    return TextStyle(
        color: Color.fromARGB(136, 59, 58, 58),
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins');
  }

  static TextStyle semiBooldTextFeilsStyle() {
    return TextStyle(
        color: Color.fromARGB(255, 12, 1, 1),
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins');
  }
}
