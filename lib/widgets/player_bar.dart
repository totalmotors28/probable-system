import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerBar extends StatelessWidget {
  final AudioPlayer player;
  final String? currentTitle;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const PlayerBar({
    super.key,
    required this.player,
    this.currentTitle,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final processingState = state?.processingState;
        final playing = state?.playing ?? false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentTitle != null) ...[
                Text(
                  currentTitle!,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = player.duration ?? Duration.zero;
                  return ProgressBar(
                    progress: position,
                    total: duration,
                    onSeek: player.seek,
                    barHeight: 3,
                    thumbRadius: 6,
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 32,
                    tooltip: 'Öňki',
                    onPressed: onPrevious,
                  ),
                  IconButton(
                    icon: Icon(
                      processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering
                          ? Icons.hourglass_empty
                          : playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                    ),
                    iconSize: 56,
                    tooltip: playing ? 'Duruz' : 'Çal',
                    onPressed: () {
                      if (playing) {
                        player.pause();
                      } else {
                        player.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 32,
                    tooltip: 'Indiki',
                    onPressed: onNext,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
