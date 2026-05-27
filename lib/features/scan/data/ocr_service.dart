import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Reads lab reports.
///
/// PDFs are read via their embedded text layer first (accurate, no OCR
/// guesswork); only image-based / scanned PDFs fall back to rasterize + OCR.
/// Photos are always OCR'd.
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeImage(String path) async {
    final result =
        await _recognizer.processImage(InputImage.fromFilePath(path));
    return result.text;
  }

  /// Extracts the embedded text layer of a PDF, preserving spatial layout so
  /// each result row (name · value · range) stays on one line.
  Future<String> _extractPdfTextLayer(List<int> bytes) async {
    try {
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText(layoutText: true);
      doc.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }

  /// Returns true when the extracted text has enough real content to use
  /// directly (vs. an empty/near-empty layer from a scanned PDF).
  bool _hasUsableText(String text) {
    final digits = RegExp(r'\d').allMatches(text).length;
    return text.trim().length >= 40 && digits >= 5;
  }

  Future<String> recognizePdf(File pdf, {int maxPages = 5}) async {
    final bytes = await pdf.readAsBytes();

    // 1) Prefer the embedded text layer.
    final layerText = await _extractPdfTextLayer(bytes);
    if (_hasUsableText(layerText)) return layerText;

    // 2) Fallback: rasterize each page and OCR (scanned PDFs).
    final dir = await getTemporaryDirectory();
    final buffer = StringBuffer();
    var page = 0;
    await for (final raster in Printing.raster(bytes, dpi: 250)) {
      if (page >= maxPages) break;
      final png = await raster.toPng();
      final file = File(
          '${dir.path}/ocr_page_${DateTime.now().microsecondsSinceEpoch}_$page.png');
      await file.writeAsBytes(png);
      buffer.writeln(await recognizeImage(file.path));
      try {
        await file.delete();
      } catch (_) {}
      page++;
    }
    return buffer.toString();
  }

  void dispose() => _recognizer.close();
}
