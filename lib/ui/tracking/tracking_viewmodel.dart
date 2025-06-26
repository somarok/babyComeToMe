import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _keyStartTime = 'lastStartTime';
  static const _keyPhase = 'lastPhase';
  static const _keySessions = 'savedSessions';

  void toggle() {
    final now = DateTime.now();

    switch (state.phase) {
      case TrackingPhase.idle:
        // 진통 시작
        state = state.copyWith(
          phase: TrackingPhase.contracting,
          tempStartTime: now,
        );
        saveTrackingState(now, TrackingPhase.contracting);
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
        saveTrackingState(now, TrackingPhase.resting);
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
        saveTrackingState(now, TrackingPhase.contracting);
        break;
    }
    _saveState();
  }

  void reset() {
    state = const TrackingState();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_keyStartTime);
      prefs.remove(_keyPhase);
      prefs.remove(_keySessions);
    });
  }

  void stopTracking() {
    state = state.copyWith(phase: TrackingPhase.idle);
    _saveState();
  }

  /// 앱 종료 전 또는 상태 변경 시 저장
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    // phase & tempStartTime
    if (state.tempStartTime != null) {
      prefs.setString(_keyStartTime, state.tempStartTime!.toIso8601String());
      prefs.setString(_keyPhase, _phaseToString(state.phase));
    } else {
      prefs.remove(_keyStartTime);
      prefs.remove(_keyPhase);
    }
    // sessions
    final jsonList = state.sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_keySessions, jsonList);
  }

  /// 앱 재실행 시 호출해서 상태 복원
  Future<void> restoreTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTime = prefs.getString('lastStartTime');
    final rawPhase = prefs.getString('lastPhase');

    if (rawTime != null && rawPhase != null) {
      final restoredStart = DateTime.tryParse(rawTime);
      final restoredPhase = _parsePhase(rawPhase);
      if (restoredStart != null && restoredPhase != null) {
        state = state.copyWith(
          tempStartTime: restoredStart,
          phase: restoredPhase,
        );
      }
    }
    final saved = prefs.getStringList(_keySessions);
    if (saved != null) {
      final list = saved.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        return ContractionSession.fromJson(map);
      }).toList();
      state = state.copyWith(sessions: list);
    }
  }

  Future<void> saveTrackingState(DateTime time, TrackingPhase phase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastStartTime', time.toIso8601String());
    await prefs.setString('lastPhase', _phaseToString(phase));
  }

  /// 저장 제거
  Future<void> clearTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastStartTime');
    await prefs.remove('lastPhase');
  }

  String _phaseToString(TrackingPhase phase) {
    switch (phase) {
      case TrackingPhase.contracting:
        return 'contraction';
      case TrackingPhase.resting:
        return 'rest';
      default:
        return 'idle';
    }
  }

  TrackingPhase? _parsePhase(String raw) {
    switch (raw) {
      case 'contraction':
        return TrackingPhase.contracting;
      case 'rest':
        return TrackingPhase.resting;
      default:
        return null;
    }
  }

  /// 세션 인덱스로 삭제
  void removeSessionAt(int index) {
    if (index < 0 || index >= state.sessions.length) return;
    final sessions = List<ContractionSession>.from(state.sessions);
    final removed = sessions[index];
    // 이전 세션이 존재하면 nextContractionStart를 조정
    if (index > 0) {
      final prev = sessions[index - 1];
      final updatedPrev = ContractionSession(
        contractionStart: prev.contractionStart,
        contractionEnd: prev.contractionEnd,
        nextContractionStart: removed.nextContractionStart,
      );
      sessions[index - 1] = updatedPrev;
    }
    sessions.removeAt(index);
    state = state.copyWith(sessions: sessions);
    _saveState();
  }
}
