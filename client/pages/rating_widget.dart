import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final Color borderColor;
  final int starCount;

  StarRating({
    required this.rating,
    required this.size,
    required this.color,
    required this.borderColor,
    required this.starCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: size,
          color: index < rating ? color : borderColor,
        );
      }),
    );
  }
}
