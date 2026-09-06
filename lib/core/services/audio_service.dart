// Reusable audio feedback service for successful application operations.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Contract used by controllers without exposing the audio package directly.
abstract interface class SuccessAudioPlayer {
  /// Plays the shared success sound when no previous playback is active.
  Future<void> playSuccess();
}

/// Owns one audio player and prevents overlapping success sounds.
class AudioService implements SuccessAudioPlayer {
  AudioService({AudioPlayer Function()? playerFactory})
    : _playerFactory = playerFactory ?? AudioPlayer.new;

  static const _successAsset = 'sounds/success.mp3';

  final AudioPlayer Function() _playerFactory;

  AudioPlayer? _player;
  Future<void>? _initialization;
  StreamSubscription<void>? _completionSubscription;

  bool _isPlaying = false;
  bool _isDisposed = false;

  /// Starts one success sound and ignores requests until playback completes.
  @override
  Future<void> playSuccess() async {
    if (_isPlaying || _isDisposed) {
      return;
    }

    _isPlaying = true;
    try {
      await _initializeOnce();
      if (_isDisposed) {
        _isPlaying = false;
        return;
      }
      await _player!.play(AssetSource(_successAsset));
    } on Object catch (error) {
      // Audio feedback must never turn a completed operation into a failure.
      _isPlaying = false;
      debugPrint('Unable to play success sound: $error');
    }
  }

  /// Creates and configures the native player only on the first playback.
  Future<void> _initializeOnce() {
    final existingInitialization = _initialization;
    if (existingInitialization != null) {
      return existingInitialization;
    }

    final player = _playerFactory();
    _player = player;
    _completionSubscription = player.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });
    return _initialization = player.setReleaseMode(ReleaseMode.stop);
  }

  /// Releases the stream subscription and native audio player resources.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _isPlaying = false;
    await _completionSubscription?.cancel();
    await _player?.dispose();
  }
}
