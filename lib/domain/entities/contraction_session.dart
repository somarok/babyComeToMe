// lib/domain/entities/contraction_session.dart

class ContractionSession {
  final DateTime contractionStart;
  final DateTime contractionEnd;
  final DateTime? nextContractionStart; // 이 회차의 휴식 종료 = 다음 회차 진통 시작

  ContractionSession({
    required this.contractionStart,
    required this.contractionEnd,
    this.nextContractionStart,
  });

  Duration get contractionDuration =>
      contractionEnd.difference(contractionStart);

  Duration? get restDuration =>
      nextContractionStart?.difference(contractionEnd);

  @override
  String toString() {
    return 'ContractionSession(start: $contractionStart, end: $contractionEnd, nextStart: $nextContractionStart)';
  }

  Map<String, dynamic> toJson() => {
        'contractionStart': contractionStart.toIso8601String(),
        'contractionEnd': contractionEnd.toIso8601String(),
        'nextContractionStart': nextContractionStart?.toIso8601String(),
      };

  static ContractionSession fromJson(Map<String, dynamic> json) {
    return ContractionSession(
      contractionStart: DateTime.parse(json['contractionStart'] as String),
      contractionEnd: DateTime.parse(json['contractionEnd'] as String),
      nextContractionStart: json['nextContractionStart'] != null
          ? DateTime.parse(json['nextContractionStart'] as String)
          : null,
    );
  }
}

extension ContractionSessionExtension on ContractionSession {
  Duration? get totalDuration {
    if (nextContractionStart == null) return null;
    return nextContractionStart!.difference(contractionStart);
  }
}
