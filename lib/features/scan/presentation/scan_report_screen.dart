import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _status = t.scanReadingDocument;
    });
    try {
      final reference =
          await ref.read(referenceBiomarkersProvider.future);
      final text = await recognize();
      setState(() => _status = t.scanFindingBiomarkers);
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
        content: Text(t.scanFailed(e.toString())),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showRawText(String text) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.scanNoValuesTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.scanNoValuesBody,
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
                      text.isEmpty ? t.scanNoTextDetected : text,
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
            child: Text(t.scanClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.scanTitle)),
      body: _busy
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AnimatedLablioLogo(size: 64, repeat: true),
                  const SizedBox(height: 16),
                  Text(_status,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(t.scanExtractAuto,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  t.scanIntroBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _ScanOption(
                  icon: Icons.camera_alt_outlined,
                  title: t.scanOptionPhoto,
                  subtitle: t.scanOptionPhotoSub,
                  onTap: () => _scanImage(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                _ScanOption(
                  icon: Icons.image_outlined,
                  title: t.scanOptionImage,
                  subtitle: t.scanOptionImageSub,
                  onTap: () => _scanImage(ImageSource.gallery),
                ),
                const SizedBox(height: 12),
                _ScanOption(
                  icon: Icons.picture_as_pdf_outlined,
                  title: t.scanOptionPdf,
                  subtitle: t.scanOptionPdfSub,
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
