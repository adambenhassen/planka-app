import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/models.dart';

String _formatElapsed(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Elapsed seconds of a Planka stopwatch as of [now].
Duration stopwatchElapsed(PlankaStopwatch sw, DateTime now) {
  final running = sw.startedAt;
  final extra =
      running == null ? Duration.zero : now.toUtc().difference(running.toUtc());
  return Duration(seconds: sw.total) + (extra.isNegative ? Duration.zero : extra);
}

class CardStopwatchSection extends StatefulWidget {
  const CardStopwatchSection({
    super.key,
    required this.stopwatch,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  final PlankaStopwatch? stopwatch;

  /// Called with the accumulated seconds so far to (re)start the clock.
  final ValueChanged<int> onStart;

  /// Called with the new accumulated seconds to pause the clock.
  final ValueChanged<int> onPause;
  final VoidCallback onReset;

  @override
  State<CardStopwatchSection> createState() => _CardStopwatchSectionState();
}

class _CardStopwatchSectionState extends State<CardStopwatchSection> {
  Timer? _ticker;

  @override
  void didUpdateWidget(CardStopwatchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  void _syncTicker() {
    final running = widget.stopwatch?.startedAt != null;
    if (running && _ticker == null) {
      _ticker = Timer.periodic(
          const Duration(seconds: 1), (_) => setState(() {}));
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.stopwatch;
    if (sw == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.timer_outlined, size: 18),
          label: const Text('Start stopwatch'),
          onPressed: () => widget.onStart(0),
        ),
      );
    }
    final elapsed = stopwatchElapsed(sw, DateTime.now());
    final running = sw.startedAt != null;
    return Row(
      children: [
        Icon(Icons.timer_outlined,
            size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          _formatElapsed(elapsed),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(running ? Icons.pause : Icons.play_arrow),
          tooltip: running ? 'Pause' : 'Resume',
          onPressed: () => running
              ? widget.onPause(elapsed.inSeconds)
              : widget.onStart(sw.total),
        ),
        IconButton(
          icon: const Icon(Icons.restart_alt),
          tooltip: 'Reset stopwatch',
          onPressed: widget.onReset,
        ),
      ],
    );
  }
}
