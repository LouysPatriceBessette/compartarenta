import 'dart:math' as math;

/// Tank-to-tank fuel consumption split by driving condition (route / city / traffic).
///
/// Each full-tank interval *j* supplies one equation:
/// `fuel_j = c_route * d_route_j + c_city * d_city_j + c_traffic * d_traffic_j`
/// where `d_*_j` are kilometres attributed to each condition (from session
/// distance × user-declared integer percents).
///
/// Coefficients `c_*` (L/km) are estimated with non-negative least squares
/// (Lawson–Hanson) across all intervals — the same linear model used in OBD/GNSS
/// fuel virtual-sensing literature when only aggregate tank volumes are known.
class DrivingConditionConsumptionInput {
  const DrivingConditionConsumptionInput({
    required this.routeKm,
    required this.cityKm,
    required this.trafficKm,
    required this.fuelLiters,
  });

  final double routeKm;
  final double cityKm;
  final double trafficKm;
  final double fuelLiters;

  double get totalKm => routeKm + cityKm + trafficKm;
}

class DrivingConditionConsumptionResult {
  const DrivingConditionConsumptionResult({
    required this.litersPerKmRoute,
    required this.litersPerKmCity,
    required this.litersPerKmTraffic,
  });

  final double litersPerKmRoute;
  final double litersPerKmCity;
  final double litersPerKmTraffic;

  double get litersPer100KmRoute => litersPerKmRoute * 100;
  double get litersPer100KmCity => litersPerKmCity * 100;
  double get litersPer100KmTraffic => litersPerKmTraffic * 100;

  /// Blended L/100 km over the summed mode distances in the fit window.
  double blendedLitersPer100Km({
    required double totalRouteKm,
    required double totalCityKm,
    required double totalTrafficKm,
  }) {
    final d = totalRouteKm + totalCityKm + totalTrafficKm;
    if (d <= 0) return 0;
    final liters = litersPerKmRoute * totalRouteKm +
        litersPerKmCity * totalCityKm +
        litersPerKmTraffic * totalTrafficKm;
    return (liters / d) * 100;
  }
}

/// Minimum number of full-tank intervals with driving-mix data required before
/// reporting per-condition consumption.
const int kMinFullTankIntervalsForDrivingConditionConsumption = 2;

/// Returns `null` when fewer than [kMinFullTankIntervalsForDrivingConditionConsumption]
/// usable intervals are supplied or the fit is degenerate.
DrivingConditionConsumptionResult? solveDrivingConditionConsumption(
  List<DrivingConditionConsumptionInput> intervals,
) {
  if (intervals.length < kMinFullTankIntervalsForDrivingConditionConsumption) {
    return null;
  }
  final rows = <List<double>>[];
  final targets = <double>[];
  for (final interval in intervals) {
    if (interval.fuelLiters <= 0 || interval.totalKm <= 0) continue;
    rows.add([interval.routeKm, interval.cityKm, interval.trafficKm]);
    targets.add(interval.fuelLiters);
  }
  if (rows.length < kMinFullTankIntervalsForDrivingConditionConsumption) {
    return null;
  }
  final coeffs = _nnls(rows, targets);
  if (coeffs == null) return null;
  final route = coeffs[0];
  final city = coeffs[1];
  final traffic = coeffs[2];
  if (route < 0 || city < 0 || traffic < 0) return null;
  if (route == 0 && city == 0 && traffic == 0) return null;
  return DrivingConditionConsumptionResult(
    litersPerKmRoute: route,
    litersPerKmCity: city,
    litersPerKmTraffic: traffic,
  );
}

/// Non-negative least squares for `min ||Ax - b||²`, `x >= 0`.
///
/// Enumerates active sets (feasible for [n] ≤ 8); exact for our three modes.
List<double>? _nnls(List<List<double>> a, List<double> b) {
  final m = a.length;
  final n = a.first.length;
  if (m == 0 || n == 0 || a.any((row) => row.length != n) || b.length != m) {
    return null;
  }

  List<double>? best;
  var bestResidual = double.infinity;
  var bestNorm = double.infinity;

  for (var mask = 0; mask < (1 << n); mask++) {
    final active = <int>[];
    for (var j = 0; j < n; j++) {
      if ((mask & (1 << j)) != 0) active.add(j);
    }

    final x = List<double>.filled(n, 0);
    if (active.isNotEmpty) {
      final sub = _solveUnconstrainedLeastSquares(a, b, active);
      if (sub == null) continue;
      var feasible = true;
      for (var i = 0; i < active.length; i++) {
        if (sub[i] < -1e-9) {
          feasible = false;
          break;
        }
        x[active[i]] = sub[i];
      }
      if (!feasible) continue;
    }

    var residual = 0.0;
    for (var i = 0; i < m; i++) {
      var pred = 0.0;
      for (var j = 0; j < n; j++) {
        pred += a[i][j] * x[j];
      }
      final d = b[i] - pred;
      residual += d * d;
    }
    if (residual < bestResidual - 1e-12) {
      bestResidual = residual;
      bestNorm = _l2Norm(x);
      best = x;
    } else if ((residual - bestResidual).abs() <= 1e-12) {
      final norm = _l2Norm(x);
      if (norm < bestNorm) {
        bestNorm = norm;
        best = x;
      }
    }
  }

  return best;
}

double _l2Norm(List<double> x) {
  var sum = 0.0;
  for (final v in x) {
    sum += v * v;
  }
  return math.sqrt(sum);
}

List<double>? _solveUnconstrainedLeastSquares(
  List<List<double>> a,
  List<double> b,
  List<int> active,
) {
  final p = active.length;
  if (p == 0) return const [];

  // Normal equations Aa' Aa x = Aa' b for active columns.
  final ata = List.generate(p, (_) => List<double>.filled(p, 0));
  final atb = List<double>.filled(p, 0);
  for (var i = 0; i < a.length; i++) {
    final row = a[i];
    final bi = b[i];
    for (var c1 = 0; c1 < p; c1++) {
      final v1 = row[active[c1]];
      atb[c1] += v1 * bi;
      for (var c2 = 0; c2 < p; c2++) {
        ata[c1][c2] += v1 * row[active[c2]];
      }
    }
  }
  return _solveSymmetric(ata, atb);
}

List<double>? _solveSymmetric(List<List<double>> a, List<double> b) {
  final n = b.length;
  final m = a.map((row) => List<double>.from(row)).toList();
  final x = List<double>.from(b);

  for (var k = 0; k < n; k++) {
    var pivot = m[k][k];
    if (pivot.abs() < 1e-12) return null;
    for (var i = k + 1; i < n; i++) {
      final factor = m[i][k] / pivot;
      for (var j = k; j < n; j++) {
        m[i][j] -= factor * m[k][j];
      }
      x[i] -= factor * x[k];
    }
  }

  final result = List<double>.filled(n, 0);
  for (var i = n - 1; i >= 0; i--) {
    var sum = x[i];
    for (var j = i + 1; j < n; j++) {
      sum -= m[i][j] * result[j];
    }
    final diag = m[i][i];
    if (diag.abs() < 1e-12) return null;
    result[i] = sum / diag;
  }
  return result;
}

/// Integer driving-mix percents (each 0–100, sum exactly 100).
bool drivingMixPercentsValid(int route, int city, int traffic) {
  if (route < 0 || city < 0 || traffic < 0) return false;
  return route + city + traffic == 100;
}

double modeKmFromSession({
  required int usageAmountTenths,
  required int percent,
}) {
  if (usageAmountTenths <= 0 || percent <= 0) return 0;
  return (usageAmountTenths / 10.0) * (percent / 100.0);
}
