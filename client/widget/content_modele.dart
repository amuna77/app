import 'package:flutter/material.dart';

class UnboardingContent {
  String image;
  String title;
  String description;
  UnboardingContent(
      {required this.description, required this.image, required this.title});
}

List<UnboardingContent> contents = [
  UnboardingContent(
      description: 'Pick your product',
      image: "images/screen1.png",
      title: 'Select from our Best products'),
  UnboardingContent(
      description:
          'You  can pay cash on delivery\n and Card payment is available',
      image: "images/screen2.png",
      title: 'Easy and Online Payment'),
  UnboardingContent(
      description: 'Deliver your product at your\n Doorstep ',
      image: "images/screen3.png",
      title: 'Quick Delivery at Your Doorstep'),
];
