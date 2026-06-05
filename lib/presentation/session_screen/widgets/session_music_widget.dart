import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../../../theme/app_theme.dart';

class SessionMusicWidget extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onToggle;

  const SessionMusicWidget({
    super.key,
    required this.isPlaying,
    required this.onToggle,
  });

  @override
  State<SessionMusicWidget> createState() => _SessionMusicWidgetState();
}

class _SessionMusicWidgetState extends State<SessionMusicWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AudioPlayer _player;
  int _selectedTrack = 0;
  bool _isLoading = false;

  // Track list unchanged
  final List<Map<String, dynamic>> _tracks = [
    {
      'title': 'Deep Focus Flow',
      'artist': 'Lo-Fi Study Beats',
      'label': 'Deep',
      'url': 'assets/audio/deep.mp3',
    },
    {
      'title': 'Rain & Coffee Shop',
      'artist': 'Ambient Sounds',
      'label': 'Rain',
      'url': 'assets/audio/rain.mp3',
    },
    {
      'title': 'Forest Meditation',
      'artist': 'Nature Sounds',
      'label': 'Forest',
      'url': 'assets/audio/forest.mp3',
    },
    {
      'title': 'Space Odyssey',
      'artist': 'Instrumental Chill',
      'label': 'Space',
      'url': 'assets/audio/space.mp3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initAudio();
  }

  // ── Audio logic (unchanged) ───────────────────────────────────────────────

  Future<void> _initAudio() async {
    _player = AudioPlayer();
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await _loadTrack(_selectedTrack);
  }

  Future<void> _loadTrack(int index) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final track = _tracks[index];
      await _player.setAudioSource(
        AudioSource.asset(
          track['url'] as String,
          tag: MediaItem(
            id: index.toString(),
            title: track['title'] as String,
            artist: track['artist'] as String,
            displayTitle: track['title'] as String,
            displaySubtitle: track['artist'] as String,
          ),
        ),
      );
      _player.setLoopMode(LoopMode.one);
      if (widget.isPlaying) {
        await _player.play();
        _waveController.repeat(reverse: true);
      }
    } catch (e) {
      debugPrint('Audio load error $index: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlayback() async {
    widget.onToggle();
    if (_player.playing) {
      await _player.pause();
      _waveController.stop();
      _waveController.reset();
    } else {
      await _player.play();
      _waveController.repeat(reverse: true);
    }
  }

  Future<void> _selectTrack(int index) async {
    if (index == _selectedTrack) return;
    final wasPlaying = _player.playing;
    setState(() => _selectedTrack = index);
    await _player.stop();
    await _loadTrack(index);
    if (wasPlaying) {
      await _player.play();
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SessionMusicWidget old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (!widget.isPlaying && _player.playing) {
        _player.pause();
        _waveController.stop();
        _waveController.reset();
      } else if (widget.isPlaying && !_player.playing) {
        _player.play();
        _waveController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final track = _tracks[_selectedTrack];
    final bool playing = widget.isPlaying;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: playing
              ? AppTheme.accent.withOpacity(0.2)
              : AppTheme.borderSubtle,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              // Track icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.accentTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: AppTheme.accent, size: 18),
              ),

              const SizedBox(width: 12),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['title'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _isLoading
                          ? 'Loading...'
                          : track['artist'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Wave animation when playing
              if (playing && !_isLoading)
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(4, (i) {
                      final heights = [8.0, 14.0, 10.0, 16.0];
                      final h = heights[i] *
                          (0.5 +
                              0.5 *
                                  (i % 2 == 0
                                      ? _waveController.value
                                      : 1 - _waveController.value));
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          width: 2.5,
                          height: h,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              if (_isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.accent,
                  ),
                ),

              const SizedBox(width: 10),

              // Play/pause button
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayback,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: playing ? AppTheme.accent : AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: playing
                          ? Colors.transparent
                          : AppTheme.borderDefault,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: playing
                        ? Colors.white
                        : AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Track selector chips ──
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tracks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final bool isSelected = i == _selectedTrack;
                return GestureDetector(
                  onTap: () => _selectTrack(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentTint
                          : AppTheme.backgroundSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accent.withOpacity(0.3)
                            : AppTheme.borderSubtle,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _tracks[i]['label'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}