import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';
import '../data/profile_model.dart';

/// Builds and shares a PDF summary suitable for taking to a doctor visit.
class DoctorReportService {
  Future<File> generate({
    required ProfileModel? profile,
    required List<BiomarkerEntryModel> entries,
  }) async {
    // Latest reading per biomarker, oldest→newest order.
    final byMarker = <String, BiomarkerEntryModel>{};
    for (final e in entries) {
      final cur = byMarker[e.biomarkerId];
      if (cur == null || cur.date.isBefore(e.date)) byMarker[e.biomarkerId] = e;
    }
    final latest = byMarker.values.toList()
      ..sort((a, b) {
        // Out of range first, then by category, then by name.
        int rank(BiomarkerEntryModel x) {
          if (x.isHigh || x.isLow) return 0;
          if (x.isNormal) return 1;
          return 2;
        }
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        final c = a.biomarkerCategory.compareTo(b.biomarkerCategory);
        if (c != 0) return c;
        return a.biomarkerName.compareTo(b.biomarkerName);
      });

    final doc = pw.Document();
    final now = DateTime.now();

    String statusText(BiomarkerEntryModel e) {
      if (e.isNormal) return 'Normal';
      if (e.isHigh) return 'HIGH';
      if (e.isLow) return 'LOW';
      return '—';
    }

    PdfColor statusColor(BiomarkerEntryModel e) {
      if (e.isHigh) return PdfColor.fromHex('#EF4444');
      if (e.isLow) return PdfColor.fromHex('#F59E0B');
      if (e.isNormal) return PdfColor.fromHex('#10B981');
      return PdfColors.grey700;
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 32, 28, 28),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey400)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Lablio — Health Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0077B6'),
                )),
            pw.Text(DateFormat('MMM d, yyyy').format(now),
                style: const pw.TextStyle(color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(
                color: PdfColors.grey600, fontSize: 9)),
      ),
      build: (ctx) {
        final name = profile?.fullName ?? '—';
        final dob = profile?.dateOfBirth == null
            ? '—'
            : DateFormat('MMM d, yyyy').format(profile!.dateOfBirth!);
        final age = profile?.age?.toString() ?? '—';
        final sex = (profile?.sex ?? '—');
        final blood = profile?.bloodType ?? '—';

        return [
          pw.SizedBox(height: 12),
          // Patient block
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F7FB'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _patientCol('Patient', name),
                _patientCol('Date of birth', dob),
                _patientCol('Age', age),
                _patientCol('Sex', sex.isEmpty ? '—' : sex),
                _patientCol('Blood', blood),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
              'Latest result per biomarker (out-of-range listed first). '
              'Reference ranges shown are those captured at the time of each result.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),

          // Table
          pw.Table(
            border: pw.TableBorder.symmetric(
                inside: const pw.BorderSide(
                    color: PdfColors.grey300, width: 0.4)),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2.4),
              3: pw.FlexColumnWidth(1.4),
              4: pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _th('Biomarker'),
                  _th('Value'),
                  _th('Reference'),
                  _th('Status'),
                  _th('Date'),
                ],
              ),
              for (final e in latest)
                pw.TableRow(children: [
                  _td('${e.biomarkerName}\n${e.biomarkerCategory}',
                      bold: true),
                  _td('${e.value} ${e.unit}'),
                  _td(e.refRangeLow != null && e.refRangeHigh != null
                      ? '${e.refRangeLow} – ${e.refRangeHigh} ${e.unit}'
                      : '—'),
                  _tdColored(statusText(e), statusColor(e)),
                  _td(DateFormat('MMM d, yyyy').format(e.date)),
                ]),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
              'Generated by Lablio. For informational purposes only — not a medical diagnosis.',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600)),
        ];
      },
    ));

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd').format(now);
    final file = File('${dir.path}/lablio_summary_$stamp.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> share({
    required ProfileModel? profile,
    required List<BiomarkerEntryModel> entries,
  }) async {
    final file = await generate(profile: profile, entries: entries);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Lablio Health Summary',
        text: 'My biomarker summary from Lablio.',
      ),
    );
  }

  // ── PDF helpers ─────────────────────────────────────────
  static pw.Widget _th(String t) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.grey800)),
      );

  static pw.Widget _td(String t, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  static pw.Widget _tdColored(String t, PdfColor color) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      );

  static pw.Widget _patientCol(String label, String value) => pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
}
