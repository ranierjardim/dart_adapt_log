import 'dart:typed_data';

/// Imagem extraída de uma entry de screenshot.
class StoredScreenshot {
  final String format;
  final int? width;
  final int? height;
  final Uint8List bytes;

  const StoredScreenshot({
    required this.format,
    required this.width,
    required this.height,
    required this.bytes,
  });

  String get contentType => format == 'png' ? 'image/png' : 'application/octet-stream';
}
