import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class BlurDetectionService {
  // Threshold tuned for phone camera photos.
  // Values below this = blurry. Raise to be stricter, lower to be more lenient.
  static const double _blurThreshold = 1100.0;

  /// Returns true if the image is too blurry to process.
  /// Runs on an isolate so it never jank the UI thread.
  static Future<bool> isBlurry(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final variance = await compute(_computeLaplacianVariance, bytes);
      print('🔢 BLUR VARIANCE: $variance | THRESHOLD: $_blurThreshold | IS BLURRY: ${variance < _blurThreshold}');
      return variance < _blurThreshold;
    } catch (e) {
      debugPrint('BlurDetectionService error: $e');
      return false; // fail open — let Gemini handle it
    }
  }

  /// Computes the Laplacian variance of an image.
  ///
  /// High variance = lots of edges = sharp image.
  /// Low variance  = smooth gradients = blurry image.
  ///
  /// This runs inside compute() so it is safe to do heavy work here.
  static double _computeLaplacianVariance(Uint8List bytes) {
    // Decode and resize to a fixed small size so computation is fast
    // regardless of the original photo resolution.
    img.Image? original = img.decodeImage(bytes);
    if (original == null) return 999.0; // cannot decode → assume sharp

    // Resize to max 200×200 — enough detail for blur detection, very fast
    final img.Image small = img.copyResize(
      original,
      width: original.width > original.height ? 200 : -1,
      height: original.height >= original.width ? 200 : -1,
    );

    // Convert to grayscale
    final img.Image gray = img.grayscale(small);

    final int w = gray.width;
    final int h = gray.height;

    // Laplacian kernel: highlights edges
    // [ 0,  1, 0]
    // [ 1, -4, 1]
    // [ 0,  1, 0]
    final List<double> laplacian = [];

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final double center = _luma(gray, x, y);
        final double top    = _luma(gray, x, y - 1);
        final double bottom = _luma(gray, x, y + 1);
        final double left   = _luma(gray, x - 1, y);
        final double right  = _luma(gray, x + 1, y);

        final double response = top + bottom + left + right - 4 * center;
        laplacian.add(response);
      }
    }

    if (laplacian.isEmpty) return 0.0;

    // Compute variance of Laplacian responses
    final double mean = laplacian.reduce((a, b) => a + b) / laplacian.length;
    final double variance = laplacian
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        laplacian.length;

    return variance;
  }

  /// Extracts luma (brightness) from a grayscale pixel at (x, y).
  static double _luma(img.Image image, int x, int y) {
    final pixel = image.getPixel(x, y);
    // For grayscale images all channels are equal; use red channel.
    return pixel.r.toDouble();
  }
}