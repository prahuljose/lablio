import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../data/lab_report_parser.dart';
import '../data/ocr_service.dart';

class ScanReportScreen extends ConsumerStatefulWidget {
  const ScanReportScreen({super.key});

  @override
  ConsumerState<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends ConsumerState<ScanReportScreen> {
  final _ocr = OcrService();
  bool _busy = false;
  String _status = '';

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _scanImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    await _process(() => _ocr.recognizeImage(picked.path));
  }

  Future<void> _scanPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = res?.files.single.path;
    if (path == null) return;
    await _process(() => _ocr.recognizePdf(File(path)));
  }

  Future<void> _process(Future<String> Function() recognize) async {
    setState(() {
      _busy = true;
      _status = 'Reading document…';
    });
    try {
      final reference =
          await ref.read(referenceBiomarkersProvider.future);
      final text = await recognize();
      setState(() => _status = 'Finding biomarkers…');
      final result = LabReportParser.parse(text, reference);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = '';
      });
      if (result.candidates.isEmpty) {
        _showRawText(result.rawText);
        return;
      }
      context.push(AppRoutes.reviewExtraction, extra: result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Scan failed: $e'),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showRawText(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No values recognized'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Couldn\'t match any biomarkers. Here is exactly what the scan '
                'read — you can copy it to refine the scan or enter values manually.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text.isEmpty ? '(no text detected)' : text,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a report')),
      body: _busy
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Extract values automatically',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Take a photo or pick a PDF of your lab report. Everything is '
                  'processed on your device — nothing is uploaded for scanning. '
                  'You\'ll review the results before anything is saved.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _ScanOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take a photo',
                  subtitle: 'Capture the report with your camera',
                  onTap: () => _scanImage(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                _ScanOption(
                  icon: Icons.image_outlined,
                  title: 'Choose an image',
                  subtitle: 'Pick a photo from your gallery',
                  onTap: () => _scanImage(ImageSource.gallery),
                ),
                const SizedBox(height: 12),
                _ScanOption(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Choose a PDF',
                  subtitle: 'Scan a PDF lab report',
                  onTap: _scanPdf,
                ),
              ],
            ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ScanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
