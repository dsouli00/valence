/// Unit conversion helpers.
///
/// Valence stores every body measurement canonically in METRIC (kg, cm). These
/// helpers convert to/from the units a user prefers, so display and input can be
/// imperial while the database stays consistent. The user's choice lives in the
/// `weightUnit` field on their user doc ('kg' = metric, 'lb' = imperial).
library;

const double _lbPerKg = 2.2046226218;
const double _cmPerInch = 2.54;

double kgToLb(double kg) => kg * _lbPerKg;
double lbToKg(double lb) => lb / _lbPerKg;

double cmToInches(double cm) => cm / _cmPerInch;
double inchesToCm(double inches) => inches * _cmPerInch;

/// Formats a height given in centimetres as feet and inches, e.g. `5'9"`.
String formatFeetInches(double cm) {
  final totalInches = (cm / _cmPerInch).round();
  final feet = totalInches ~/ 12;
  final inches = totalInches % 12;
  return "$feet'$inches\"";
}

// ---------------------------------------------------------------------------
// Weight display helpers ('kg' = metric, 'lb' = imperial; null defaults metric)
// ---------------------------------------------------------------------------

bool isMetricWeight(String? weightUnit) => weightUnit != 'lb';

/// A canonical-kg weight in the user's display unit (kg unchanged, or lb).
double displayWeight(double kg, String? weightUnit) =>
    isMetricWeight(weightUnit) ? kg : kgToLb(kg);

/// Converts a value the user typed in their display unit back to canonical kg.
double weightToKg(double value, String? weightUnit) =>
    isMetricWeight(weightUnit) ? value : lbToKg(value);

/// Formats a canonical-kg weight in the user's unit — e.g. "72.5 kg" or
/// "160 lb". Pass the localized unit labels. Metric keeps [metricDecimals]
/// decimals; imperial is shown whole (lb precision below a pound isn't useful).
String formatWeight(
  double kg,
  String? weightUnit,
  String kgLabel,
  String lbLabel, {
  int metricDecimals = 1,
}) =>
    isMetricWeight(weightUnit)
        ? '${kg.toStringAsFixed(metricDecimals)} $kgLabel'
        : '${kgToLb(kg).round()} $lbLabel';
