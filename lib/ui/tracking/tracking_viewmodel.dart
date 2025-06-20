import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/contraction_session.dart';

enum TrackingPhase {
  idle, // 아무 것도 안 하는 상태
  contracting, // 진통 중
  resting, // 진통 종료 후 휴식 중
}

class TrackingState {
  final TrackingPhase phase;
  final DateTime? tempStartTime;
  final List<ContractionSession> sessions;

  const TrackingState({
    this.phase = TrackingPhase.idle,
    this.tempStartTime,
    this.sessions = const [],
  });

  TrackingState copyWith({
    TrackingPhase? phase,
    DateTime? tempStartTime,
    List<ContractionSession>? sessions,
  }) {
    return TrackingState(
      phase: phase ?? this.phase,
      tempStartTime: tempStartTime ?? this.tempStartTime,
      sessions: sessions ?? this.sessions,
    );
  }
}

class TrackingViewModel extends StateNotifier<TrackingState> {
  TrackingViewModel() : super(const TrackingState());

  void toggle() {
    final now = DateTime.now();

    switch (state.phase) {
      case TrackingPhase.idle:
        // 진통 시작
        state = state.copyWith(
          phase: TrackingPhase.contracting,
          tempStartTime: now,
        );
        break;

      case TrackingPhase.contracting:
        // 진통 종료 → 휴식 시작
        final start = state.tempStartTime;
        if (start != null) {
          final newSession = ContractionSession(
            contractionStart: start,
            contractionEnd: now,
          );
          state = state.copyWith(
            phase: TrackingPhase.resting,
            tempStartTime: now, // now가 곧 rest 시작 시점
            sessions: [...state.sessions, newSession],
          );
        }
        break;

      case TrackingPhase.resting:
        // 휴식 종료 → 다음 진통 시작 (이전 session에 nextContractionStart 저장 필요)
        final previous = state.sessions.last;
        final updated = state.sessions.sublist(0, state.sessions.length - 1)
          ..add(
            ContractionSession(
              contractionStart: previous.contractionStart,
              contractionEnd: previous.contractionEnd,
              nextContractionStart: now,
            ),
          );

        state = state.copyWith(
          phase: TrackingPhase.contracting,
          tempStartTime: now,
          sessions: updated,
        );
        break;
    }
  }

  void reset() {
    state = const TrackingState();
  }
}
