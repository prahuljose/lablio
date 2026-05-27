import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/biomarker_entry_model.dart';
import 'biomarkers_provider.dart';

/// Direction of the latest reading vs the previous one.
enum TrendDirection { up, down, flat, none }

class BiomarkerInsight {
  final String biomarkerId;
  final String name;
  final String unit;
  final BiomarkerEntryModel latest;
  final BiomarkerEntryModel? previous;

  const BiomarkerInsight({
    required this.biomarkerId,
    required this.name,
    required this.unit,
    required this.latest,
    this.previous,
  });

  bool get outOfRange => latest.isHigh || latest.isLow;

  TrendDirection get direction {
    final p = previous;
    if (p == null) return TrendDirection.none;
    if (latest.value > p.value) return TrendDirection.up;
    if (latest.value < p.value) return TrendDirection.down;
    return TrendDirection.flat;
  }

  /// Distance of a value outside its reference range (0 when in range/unknown).
  double _excursion(BiomarkerEntryModel e) {
    final lo = e.refRangeLow, hi = e.refRangeHigh;
    if (lo == null || hi == null) return 0;
    if (e.value < lo) return lo - e.value;
    if (e.value > hi) return e.value - hi;
    return 0;
  }

  /// True when the latest reading moved meaningfully closer to / into range.
  bool get improving {
    final p = previous;
    if (p == null) return false;
    final prevEx = _excursion(p);
    final nowEx = _excursion(latest);
    return nowEx < prevEx; // smaller excursion → closer to normal
  }

  /// True when the latest reading moved further out of range.
  bool get worsening {
    final p = previous;
    if (p == null) return false;
    return _excursion(latest) > _excursion(p);
  }
}

class HealthInsights {
  final List<BiomarkerInsight> insights;
  const HealthInsights(this.insights);

  int get tracked => insights.length;
  int get outOfRange => insights.where((i) => i.outOfRange).length;
  int get improving => insights.where((i) => i.improving).length;
  int get worsening => insights.where((i) => i.worsening).length;

  /// Markers worth surfacing first: out-of-range, then changed, then the rest.
  List<BiomarkerInsight> get highlights {
    final sorted = [...insights]..sort((a, b) {
        int rank(BiomarkerInsight i) =>
            i.outOfRange ? 0 : (i.direction != TrendDirection.none ? 1 : 2);
        return rank(a).compareTo(rank(b));
      });
    return sorted;
  }
}

/// Derives per-biomarker insights (latest + previous reading) from all entries.
final healthInsightsProvider =
    Provider<AsyncValue<HealthInsights>>((ref) {
  return ref.watch(biomarkerEntriesProvider).whenData((entries) {
    final byMarker = <String, List<BiomarkerEntryModel>>{};
    for (final e in entries) {
      byMarker.putIfAbsent(e.biomarkerId, () => []).add(e);
    }
    final insights = <BiomarkerInsight>[];
    for (final list in byMarker.values) {
      // Oldest → newest so the last two are previous + latest.
      list.sort((a, b) => a.date.compareTo(b.date));
      final latest = list.last;
      final previous = list.length >= 2 ? list[list.length - 2] : null;
      insights.add(BiomarkerInsight(
        biomarkerId: latest.biomarkerId,
        name: latest.biomarkerName,
        unit: latest.unit,
        latest: latest,
        previous: previous,
      ));
    }
    return HealthInsights(insights);
  });
});
