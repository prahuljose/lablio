import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../data/doctor_report_service.dart';
import '../data/export_log_service.dart';
import '../data/medical_record_model.dart';
import '../data/profile_model.dart';

/// Renders the doctor-summary PDF on screen first, so the user reviews exactly
/// what will be shared. Share / print actions live in the preview toolbar; the
/// export is logged once the user actually shares or prints.
class PdfPreviewScreen extends StatefulWidget {
  final ProfileModel? profile;
  final List<BiomarkerEntryModel> entries;
  final List<MedicalRecordEntry> medical;
  final int biomarkerCount;
  final bool includedMedical;

  const PdfPreviewScreen({
    super.key,
    required this.profile,
    required this.entries,
    required this.medical,
    required this.biomarkerCount,
    required this.includedMedical,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  // Generate once; PdfPreview may call build() again on layout changes.
  Future<Uint8List>? _doc;
  bool _logged = false;

  Future<Uint8List> _generate(PdfPageFormat _) {
    return _doc ??= () async {
      final file = await DoctorReportService().generate(
        profile: widget.profile,
        entries: widget.entries,
        medical: widget.medical,
      );
      return file.readAsBytes();
    }();
  }

  void _logExport() {
    if (_logged) return;
    _logged = true;
    ExportLogService(Supabase.instance.client)
        .logPdfExport(
          biomarkerCount: widget.biomarkerCount,
          includedMedical: widget.includedMedical,
        )
        .catchError((_) {/* analytics failure is non-fatal */});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pdfPreviewTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: PdfPreview(
        build: _generate,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'lablio_summary.pdf',
        onShared: (_) => _logExport(),
        onPrinted: (_) => _logExport(),
        loadingWidget: const LablioLoader(size: 56),
      ),
    );
  }
}
