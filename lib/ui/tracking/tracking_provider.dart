import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tracking_viewmodel.dart';

final trackingViewModelProvider =
    StateNotifierProvider<TrackingViewModel, TrackingState>(
  (ref) => TrackingViewModel(),
);

/// 진통/휴식 상태의 실시간 경과 시간 Provider
final elapsedTimeProvider = StreamProvider<Duration?>((ref) async* {
  while (true) {
    await Future.delayed(const Duration(seconds: 1));

    final state = ref.read(trackingViewModelProvider);
    final startTime = state.tempStartTime;

    if (startTime == null || state.phase == TrackingPhase.idle) {
      yield null;
    } else {
      yield DateTime.now().difference(startTime);
    }
  }
});
