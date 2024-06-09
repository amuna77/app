import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black, // Couleur de fond noire
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit
                .contain, // Ajuste l'image pour qu'elle rentre dans l'écran
          ),
        ),
      ),
    );
  }
}
