import '../../biomarkers/data/biomarker_model.dart';

/// A biomarker value the parser believes it found in a scanned report.
class ExtractedCandidate {
  final BiomarkerModel biomarker;
  final double value;
  final String sourceLine;

  const ExtractedCandidate({
    required this.biomarker,
    required this.value,
    required this.sourceLine,
  });
}

/// Result of parsing: the matched candidates plus the raw OCR text (so the
/// user can review what was actually read and diagnose misses).
class ExtractionResult {
  final List<ExtractedCandidate> candidates;
  final String rawText;
  const ExtractionResult(this.candidates, this.rawText);
}

/// Heuristic lab-report parser.
///
/// For each non-empty line it picks the *most specific* biomarker whose name /
/// short-name / alias appears in the line, then extracts the result value that
/// follows the matched term (skipping reference-range pairs like `70-99`).
class LabReportParser {
  /// Common lab-report naming variants → biomarker id.
  static const Map<String, List<String>> _aliases = {
    'alt': ['sgpt', 'alanine'],
    'ast': ['sgot', 'aspartate'],
    'hba1c': ['a1c', 'glycated hemoglobin', 'glycohemoglobin'],
    'vitamin_d': ['25 hydroxy', '25-oh', 'calcidiol', 'vitamin d3', 'vit d'],
    'vitamin_b12': ['cobalamin', 'vit b12', 'b 12'],
    'folate': ['folic acid'],
    'hdl': ['hdl c', 'hdl cholesterol'],
    'ldl': ['ldl c', 'ldl cholesterol'],
    // 'vldl c' must outrank ldl's 'ldl c' (which is a substring of 'vldl c').
    'vldl': ['vldl c', 'vldl cholesterol'],
    'total_cholesterol': ['cholesterol total', 'total chol'],
    'non_hdl': ['non hdl'],
    'triglycerides': ['trig', 'triglyceride'],
    'tsh': ['thyroid stimulating'],
    'free_t4': ['free t4', 'ft4'],
    'free_t3': ['free t3', 'ft3'],
    'egfr': ['gfr', 'e gfr'],
    // BUN-specific only — keep "Urea" (without "nitrogen") mapping to `urea`.
    'bun': ['urea nitrogen', 'blood urea nitrogen'],
    'urea': ['urea'],
    'eag': ['estimated average glucose', 'average glucose'],
    'chol_hdl_ratio': ['chol hdl', 'cholesterol hdl ratio'],
    'ldl_hdl_ratio': ['ldl hdl'],
    'ag_ratio': ['a g ratio', 'albumin globulin'],
    'wbc': ['leukocyte', 'white blood', 'white cell', 'total wbc'],
    'rbc': ['red blood', 'erythrocyte', 'total rbc'],
    'hemoglobin': ['haemoglobin', 'hgb'],
    'hematocrit': ['packed cell volume', 'pcv', 'haematocrit'],
    'platelets': ['platelet'],
    'esr': ['sedimentation'],
    'crp': ['c reactive', 'reactive protein'],
    'psa': ['prostate specific'],
    'uric_acid': ['urate'],
    'total_bilirubin': ['bilirubin total', 'total bili'],
    'vitamin_b6': ['pyridoxine'],
    'ferritin': [],
  };

  /// Normalize for matching: lowercase, collapse thousands separators
  /// (8,980 -> 8980), keep digits + decimal points, and turn everything else
  /// into single spaces so values and decimals survive intact.
  static String _norm(String s) {
    var t = s.toLowerCase();
    final commaNum = RegExp(r'(\d),(\d)');
    while (commaNum.hasMatch(t)) {
      t = t.replaceAllMapped(commaNum, (m) => '${m[1]}${m[2]}');
    }
    return t
        .replaceAll(RegExp(r'[^a-z0-9.]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static final _rangeRe = RegExp(r'\d+(?:\.\d+)?\s*[-–]\s*\d+(?:\.\d+)?');
  static final _numberRe = RegExp(r'\d+(?:\.\d+)?');

  static List<String> _keysFor(BiomarkerModel b) {
    final keys = <String>[];
    // Full name minus any parenthetical, e.g. "Vitamin D (25-OH)" -> "vitamin d".
    final baseName =
        _norm(b.name.replaceAll(RegExp(r'\(.*?\)'), ''));
    if (baseName.isNotEmpty) keys.add(baseName);
    final shortN = _norm(b.shortName);
    if (shortN.length >= 3) keys.add(shortN);
    keys.addAll(_aliases[b.id] ?? const []);
    // Longest first so the most specific key wins.
    keys.sort((a, b) => b.length.compareTo(a.length));
    return keys;
  }

  static ExtractionResult parse(String text, List<BiomarkerModel> reference) {
    final keyTable = {for (final b in reference) b.id: _keysFor(b)};
    final byId = {for (final b in reference) b.id: b};

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final found = <String, ExtractedCandidate>{};

    for (final rawLine in lines) {
      final norm = _norm(rawLine);
      if (norm.isEmpty) continue;

      // Find the most specific (longest) key match on this line.
      String? bestId;
      String? bestKey;
      var bestLen = 0;
      for (final b in reference) {
        if (found.containsKey(b.id)) continue;
        for (final key in keyTable[b.id]!) {
          if (key.length > bestLen && norm.contains(key)) {
            bestLen = key.length;
            bestId = b.id;
            bestKey = key;
            break; // keys are longest-first per biomarker
          }
        }
      }
      if (bestId == null || bestKey == null) continue;

      final value = _valueAfter(norm, bestKey);
      if (value == null) continue;

      found[bestId] = ExtractedCandidate(
        biomarker: byId[bestId]!,
        value: value,
        sourceLine: rawLine,
      );
    }

    final list = found.values.toList()
      ..sort((a, b) => a.biomarker.name.compareTo(b.biomarker.name));
    return ExtractionResult(list, text);
  }

  /// Extract the result value appearing after [key] in a normalized line,
  /// skipping a reference range (e.g. "70-99") if it appears first.
  static double? _valueAfter(String norm, String key) {
    final idx = norm.indexOf(key);
    if (idx < 0) return null;
    var tail = norm.substring(idx + key.length);
    // Drop reference-range pairs so we don't pick the low end of a range.
    tail = tail.replaceAll(_rangeRe, ' ');
    final m = _numberRe.firstMatch(tail);
    if (m == null) return null;
    return double.tryParse(m.group(0)!);
  }
}
