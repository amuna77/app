import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelephoneInputFormatter extends TextInputFormatter {
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text
        .replaceAll(RegExp(r'\D'), ''); // Remove all non-digit characters
    newText =
        newText.replaceAllMapped(RegExp(r'^(\d{3})(\d{3})(\d{4})$'), (match) {
      return '(${match[1]}) ${match[2]}-${match[3]}';
    }); // Format as (xxx) xxx-xxxx

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
