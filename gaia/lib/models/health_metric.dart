/// Model for individual health metrics
class HealthMetric {
  final String id;
  final String name;
  final String type;
  final double value;
  final String unit;
  final DateTime date;
  final String? note;

  const HealthMetric({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.unit,
    required this.date,
    this.note,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'unit': unit,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}

/// Container for all health metrics for a user
class HealthMetricSummary {
  final List<HealthMetric> metrics;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, double> averages;

  const HealthMetricSummary({
    required this.metrics,
    required this.startDate,
    required this.endDate,
    required this.averages,
  });

  factory HealthMetricSummary.fromJson(Map<String, dynamic> json) {
    return HealthMetricSummary(
      metrics: (json['metrics'] as List<dynamic>)
          .map((m) => HealthMetric.fromJson(m as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      averages: Map<String, double>.from(json['averages'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.map((m) => m.toJson()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'averages': averages,
    };
  }
}
