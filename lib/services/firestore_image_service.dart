import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

/// Encodes a resized image as a data URI so listings can be stored in Firestore
/// without requiring a Firebase Storage billing upgrade.
class FirestoreImageService {
  // Leave room for the other Firestore fields under the 1 MiB document limit.
  static const int _maxDataUriCharacters = 650000;

  Future<String> encodeListingImage(File file) async {
    final bytes = await file.readAsBytes();
    for (final width in [640, 480, 360, 240, 160]) {
      final resizedCodec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width,
      );
      final resizedFrame = await resizedCodec.getNextFrame();
      try {
        final png = await resizedFrame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png == null) continue;
        final dataUri =
            'data:image/png;base64,${base64Encode(png.buffer.asUint8List())}';
        if (dataUri.length <= _maxDataUriCharacters) return dataUri;
      } finally {
        resizedFrame.image.dispose();
        resizedCodec.dispose();
      }
    }
    throw const FormatException(
      'รูปมีขนาดใหญ่เกินไปสำหรับบันทึกใน Firestore ลองเลือกรูปที่เล็กลง',
    );
  }
}
