import 'package:baby_come_to_me/ui/tracking/tracking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/contraction_session.dart';
import 'tracking_viewmodel.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    // 앱 실행(또는 화면이 최초 마운트) 시 저장된 상태 복원
    ref.read(trackingViewModelProvider.notifier).restoreTrackingState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingViewModelProvider);
    final viewModel = ref.read(trackingViewModelProvider.notifier);
    final elapsed = ref.watch(elapsedTimeProvider).value;
    final isContracting = state.phase == TrackingPhase.contracting;
    final isIdle = state.phase == TrackingPhase.idle;
    final sessions = state.sessions.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: viewModel.stopTracking,
            icon: const Icon(Icons.pause),
            tooltip: '기록 중지',
          ),
          IconButton(
            onPressed: viewModel.reset,
            icon: const Icon(Icons.delete_forever),
            tooltip: '전체 초기화',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildLiveTimer(state, elapsed),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: sessions.isEmpty
                  ? const Center(child: Text('기록이 없습니다.'))
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        // 실제 세션 인덱스 계산 (reversed이므로)
                        final realIndex = state.sessions.length - 1 - index;
                        return Dismissible(
                          key: Key(session.contractionStart.toIso8601String()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(Icons.delete,
                                color: Colors.white, size: 32),
                          ),
                          onDismissed: (direction) {
                            ref
                                .read(trackingViewModelProvider.notifier)
                                .removeSessionAt(realIndex);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('기록이 삭제되었습니다.')),
                            );
                          },
                          child: _buildSessionCard(
                              session, sessions.length - index, state),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: 92,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                onPressed: viewModel.toggle,
                child: Text(
                  isIdle
                      ? '진통 시작'
                      : isContracting
                          ? '진통 멈춤'
                          : '다음 진통 시작',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTimer(TrackingState state, Duration? elapsed) {
    if (elapsed == null) return const Text('측정을 위해 아래 \'진통 시작\' 버튼을 눌러주세요.');

    final isContracting = state.phase == TrackingPhase.contracting;
    return Text(
      textAlign: TextAlign.center,
      isContracting
          ? '진통 중\n ${_formatDuration(elapsed)}'
          : '휴식 중\n ${_formatDuration(elapsed)}',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSessionCard(
      ContractionSession session, int index, TrackingState state) {
    // 1) 진통 지속 시간
    final contraction = _formatDuration(session.contractionDuration);

    // 2) 휴식 시간: 이미 기록된 session.restDuration 이 우선,
    //    없으면(=ongoing rest) 화면 상태와 세션 인덱스로 판단해서 실시간 계산
    Duration? restDur = session.restDuration;
    if (restDur == null &&
        state.phase == TrackingPhase.resting &&
        index == state.sessions.length - 1) {
      // 마지막 세션이면서 지금 휴식 중이라면
      restDur = DateTime.now().difference(session.contractionEnd);
    }
    final rest = restDur != null ? _formatDuration(restDur) : '--';

    // 3) 총 소요 시간 (진통 + 휴식)
    String total;
    if (session.nextContractionStart != null) {
      total = _formatDuration(session.totalDuration!);
    } else if (state.phase == TrackingPhase.resting &&
        index == state.sessions.length - 1) {
      // ongoing rest: contractionStart → now
      total =
          _formatDuration(DateTime.now().difference(session.contractionStart));
    } else {
      total = '--';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: IntrinsicHeight(
          child: Row(
            children: [
              Text(
                '$index\n회차',
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: VerticalDivider(
                  color: Colors.deepPurple,
                  thickness: 0.8,
                  indent: 8,
                  endIndent: 8,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: '진통 ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                              text:
                                  '${_formatTime(session.contractionStart)} ~ ${_formatTime(session.contractionEnd)} ($contraction)',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              )),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '휴식 ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                              text: rest,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              )),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: RichText(
                        textAlign: TextAlign.end,
                        text: TextSpan(
                          text: '총 ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text: total,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes분 ${seconds.toString().padLeft(2, '0')}초';
    } else {
      return '${seconds.toString()}초';
    }
  }
}
