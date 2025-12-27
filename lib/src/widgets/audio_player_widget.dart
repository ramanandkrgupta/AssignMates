import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final String? label;

  const AudioPlayerWidget({
    super.key,
    required this.url,
    this.label,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = state == PlayerState.completed || state == PlayerState.stopped ? false : _isLoading;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFAF00),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: const Color(0xFFFFAF00),
                        size: 32,
                      ),
                      onPressed: () async {
                        if (_isPlaying) {
                          await _audioPlayer.pause();
                        } else {
                          setState(() => _isLoading = true);
                          await _audioPlayer.play(UrlSource(widget.url));
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                    ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.label != null)
                      Text(
                        widget.label!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        min: 0,
                        max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                        value: _position.inSeconds.toDouble(),
                        activeColor: const Color(0xFFFFAF00),
                        inactiveColor: Colors.white10,
                        onChanged: (value) async {
                          final position = Duration(seconds: value.toInt());
                          await _audioPlayer.seek(position);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
                ),
                Text(
                  _formatDuration(_duration),
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
