import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../api/services/music_service.dart';

enum RepeatMode { off, one, all }

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MusicService _musicService = MusicService();

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDemoMode = false;
  bool _demoFinished = false;

  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isShuffleEnabled => _isShuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isDemoMode => _isDemoMode;
  bool get demoFinished => _demoFinished;
  double get progress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  AudioProvider() {
    _init();
  }

  void _init() {
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;

      // Log para verificar la posición y el estado del demo
      if (_isDemoMode) {
        debugPrint(
            '🎵 DEMO MODE - Position: ${position.inSeconds}s / isDemoMode: $_isDemoMode');
      }

      if (_isDemoMode && position.inSeconds >= 10) {
        debugPrint(
            '⏹️ DEMO FINISHED - Stopping playback at ${position.inSeconds}s');
        pause();
        seek(Duration.zero);
        _isDemoMode = false;
        _demoFinished = true;
        notifyListeners();
      }

      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }

      notifyListeners();
    });
  }

  Future<void> playSong(Song song,
      {bool? demo, bool? isUserAuthenticated}) async {
    _demoFinished = false;
    debugPrint('▶️ PLAY SONG - Song: ${song.name}');
    debugPrint('   demo parameter: $demo');
    debugPrint('   isUserAuthenticated parameter: $isUserAuthenticated');

    try {
      _currentSong = song;
      // Auto-enable demo mode if user is not authenticated
      if (demo != null) {
        _isDemoMode = demo;
        debugPrint('   ✅ Demo mode set from demo parameter: $_isDemoMode');
      } else if (isUserAuthenticated != null) {
        _isDemoMode = !isUserAuthenticated;
        debugPrint(
            '   ✅ Demo mode set from isUserAuthenticated: $_isDemoMode (user auth: $isUserAuthenticated)');
      } else {
        _isDemoMode = false;
        debugPrint('   ❌ No parameters, demo mode: $_isDemoMode');
      }

      debugPrint('   🎯 FINAL isDemoMode: $_isDemoMode');

      _queue = [song];
      _currentIndex = 0;

      if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
        debugPrint('   🔊 Setting audio URL and starting playback...');
        await _audioPlayer.setUrl(song.audioUrl!);
        await _audioPlayer.play();
      } else {
        debugPrint('   ⚠️ No audio URL for song: ${song.name}');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('   ❌ Error playing song: $e');
    }
  }

  Future<void> playAlbum(Album album, {int startIndex = 0}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final songsResponse = await _musicService.getSongsByAlbum(album.id);
      if (songsResponse.success && songsResponse.data != null) {
        _queue = songsResponse.data!;
        _queue
            .sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));

        if (_queue.isNotEmpty) {
          _currentIndex = startIndex;
          await playSong(_queue[_currentIndex]);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error playing album: $e');
      notifyListeners();
    }
  }

  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    try {
      if (songs.isEmpty) return;

      _queue = List.from(songs);
      _currentIndex = startIndex;
      await playSong(_queue[_currentIndex]);
    } catch (e) {
      debugPrint('Error playing queue: $e');
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await playSong(_queue[_currentIndex]);
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
      await playSong(_queue[_currentIndex]);
    } else {
      await pause();
      await seek(Duration.zero);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _queue.length - 1;
      await playSong(_queue[_currentIndex]);
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled && _queue.length > 1) {
      final currentSong = _queue[_currentIndex];
      _queue.shuffle();
      _currentIndex = _queue.indexOf(currentSong);
    }
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void _handleSongCompletion() {
    switch (_repeatMode) {
      case RepeatMode.one:
        playSong(_queue[_currentIndex]);
        break;
      case RepeatMode.all:
      case RepeatMode.off:
        next();
        break;
    }
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;

    if (index == _currentIndex) {
      next();
    } else if (index < _currentIndex) {
      _currentIndex--;
    }

    _queue.removeAt(index);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
    _currentSong = null;
    pause();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> setUrl(String url) async {
    await _audioPlayer.setUrl(url);
  }
}
