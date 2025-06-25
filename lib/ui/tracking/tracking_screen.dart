import 'package:baby_come_to_me/ui/tracking/tracking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/contraction_session.dart';
import 'tracking_viewmodel.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingViewModelProvider);
    final viewModel = ref.read(trackingViewModelProvider.notifier);
    final isContracting = state.phase == TrackingPhase.contracting;
    final isResting = state.phase == TrackingPhase.resting;
    final isIdle = state.phase == TrackingPhase.idle;
    final elapsed = ref.watch(elapsedTimeProvider).value;
    final sessions = state.sessions.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        actions: [
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
            if (isContracting || isResting)
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
                        return _buildSessionCard(
                            session, sessions.length - index);
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: 92,
              child: ElevatedButton(
                onPressed: viewModel.toggle,
                child: Text(
                  isIdle
                      ? '진통 시작'
                      : isContracting
                          ? '진통 멈춤'
                          : '다음 진통 시작',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.deepPurple,
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
    if (elapsed == null) return const SizedBox.shrink();

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

  Widget _buildSessionCard(ContractionSession session, int index) {
    final contraction = _formatDuration(session.contractionDuration);
    final rest = session.restDuration != null
        ? _formatDuration(session.restDuration!)
        : '- 측정중';
    final total = session.totalDuration != null
        ? _formatDuration(session.totalDuration!)
        : '- 측정중';

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
