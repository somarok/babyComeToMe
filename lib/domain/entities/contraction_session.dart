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
}

extension ContractionSessionExtension on ContractionSession {
  Duration? get totalDuration {
    if (nextContractionStart == null) return null;
    return nextContractionStart!.difference(contractionStart);
  }
}
