import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (imageUrl.startsWith('data:image/') && imageUrl.contains(';base64,')) {
      try {
        final encoded = imageUrl.substring(imageUrl.indexOf(';base64,') + 8);
        image = Image.memory(
          Uint8List.fromList(base64Decode(encoded)),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback ?? const Icon(Icons.broken_image),
        );
      } on FormatException {
        return SizedBox(width: width, height: height, child: fallback ?? const Icon(Icons.broken_image));
      }
    } else {
      image = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback ?? const Icon(Icons.broken_image),
      );
    }
    return image;
  }
}
