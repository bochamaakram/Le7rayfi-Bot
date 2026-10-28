import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef SpeechResultCallback = void Function(String recognizedWords);
typedef VoiceStateCallback = void Function(bool isSpeaking);
typedef VoiceErrorCallback = void Function(String errorMessage);

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _sessionEnded = false;

  /// The latest recognized words from the current listening session.
  String _lastRecognizedWords = '';

  /// Callbacks
  VoiceErrorCallback? _onErrorCallback;
  VoidCallback? _onListeningEndedCallback;

  /// Default TTS audio parameters
  static const double defaultPitch = 0.82; // Deeper, warmer voice
  static const double defaultSpeechRate = 0.68; // Slower, clearer voice pace

  double _pitch = defaultPitch;
  double _speechRate = defaultSpeechRate;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  Future<bool> get hasPermission => _speech.hasPermission;
  bool get isAvailable => _speechInitialized && _speech.isAvailable;
  String get lastRecognizedWords => _lastRecognizedWords;
  double get pitch => _pitch;
  double get speechRate => _speechRate;

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    try {
      await _tts.setPitch(_pitch);
    } catch (_) {}
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    try {
      await _tts.setSpeechRate(_speechRate);
    } catch (_) {}
  }

  Future<void> init() async {
    // 1. Initialize TTS
    try {
      await _tts.setPitch(_pitch);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('TTS init error: $e');
    }

    // 2. Initialize STT
    await _initSpeechToText();
  }

  Future<bool> _initSpeechToText() async {
    try {
      _speechInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: ${val.errorMsg} (permanent: ${val.permanent})');
          _isListening = false;
          _onErrorCallback?.call(val.errorMsg);
        },
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
            if (!_sessionEnded) {
              _sessionEnded = true;
              _onListeningEndedCallback?.call();
            }
          }
        },
        debugLogging: kDebugMode,
      );
      final perm = await _speech.hasPermission;
      debugPrint('STT initialized: $_speechInitialized, hasPermission: $perm');
      return _speechInitialized && perm;
    } catch (e) {
      debugPrint('STT init exception: $e');
      _speechInitialized = false;
      return false;
    }
  }

  /// Normalizes locale identifier to allow comparison between
  /// 'fr-FR', 'fr_FR', 'ar-MA', 'ar_MA', etc.
  String _normalizeLocale(String locale) {
    return locale.trim().toLowerCase().replaceAll('-', '_');
  }

  /// Resolve the best available locale for speech recognition.
  /// On Android, engine locales look like 'ar_MA' or 'fr_FR'.
  Future<String?> _resolveBestLocale(String currentLang) async {
    final defaultFallback = switch (currentLang) {
      'darija' => 'ar_MA',
      'ar' => 'ar_SA',
      'fr' => 'fr_FR',
      'en' => 'en_US',
      _ => 'ar_MA',
    };

    List<String> preferred;
    if (currentLang == 'en') {
      preferred = ['en_us', 'en_gb', 'en_ca', 'en_au', 'en'];
    } else if (currentLang == 'fr') {
      preferred = ['fr_fr', 'fr_ca', 'fr_be', 'fr'];
    } else if (currentLang == 'ar') {
      preferred = ['ar_sa', 'ar_ma', 'ar_eg', 'ar_ae', 'ar'];
    } else {
      // Darija: prefer Moroccan Arabic, then North African, then Standard Arabic
      preferred = ['ar_ma', 'ar_001', 'ar_dz', 'ar_tn', 'ar_sa', 'ar_eg', 'ar_ae', 'ar'];
    }

    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) {
        debugPrint('STT: No locales returned by engine, using concrete fallback: $defaultFallback');
        return defaultFallback;
      }

      // 1. Try exact matches on normalized strings
      for (final pref in preferred) {
        for (final loc in locales) {
          if (_normalizeLocale(loc.localeId) == pref) {
            debugPrint('STT: Matched preferred locale: ${loc.localeId}');
            return loc.localeId;
          }
        }
      }

      // 2. Try prefix matches
      for (final pref in preferred) {
        for (final loc in locales) {
          if (_normalizeLocale(loc.localeId).startsWith(pref)) {
            debugPrint('STT: Matched prefix locale: ${loc.localeId}');
            return loc.localeId;
          }
        }
      }

      final langPrefix = currentLang == 'en' ? 'en' : (currentLang == 'fr' ? 'fr' : 'ar');
      for (final loc in locales) {
        if (_normalizeLocale(loc.localeId).startsWith(langPrefix)) {
          debugPrint('STT: Fallback to language locale: ${loc.localeId}');
          return loc.localeId;
        }
      }
    } catch (e) {
      debugPrint('Locale resolution error: $e');
    }

    // Always return concrete default fallback rather than null (null causes system French fallback)
    debugPrint('STT: Falling back to default locale tag: $defaultFallback');
    return defaultFallback;
  }

  Future<bool> startListening({
    required String currentLang,
    required SpeechResultCallback onResult,
    required VoidCallback onListeningEnded,
    VoiceErrorCallback? onError,
    VoidCallback? onSoundLevelChange,
  }) async {
    // Ensure initialized and permission granted
    bool hasPerm = false;
    try {
      hasPerm = await _speech.hasPermission;
    } catch (_) {}

    if (!_speechInitialized || !hasPerm) {
      final initialized = await _initSpeechToText();
      if (!initialized) {
        debugPrint('STT: Not initialized or permission denied');
        onError?.call('permission_denied');
        return false;
      }
    }

    // Stop speaking if active
    if (_isSpeaking) {
      await stopSpeaking();
    }

    _lastRecognizedWords = '';
    _sessionEnded = false;
    _onErrorCallback = onError;
    _onListeningEndedCallback = onListeningEnded;

    // Resolve best locale (concrete locale ID, never null)
    final localeId = await _resolveBestLocale(currentLang);
    debugPrint('STT: Starting listen session with locale: $localeId');

    _isListening = true;

    try {
      final listenOptions = stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation, // Optimal for conversational queries
        cancelOnError: false,
        partialResults: true,
        onDevice: false,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
        localeId: localeId,
      );

      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            _lastRecognizedWords = words;
            onResult(words);
          }
          if (result.finalResult && !_sessionEnded) {
            _sessionEnded = true;
            _isListening = false;
            onListeningEnded();
          }
        },
        onSoundLevelChange: onSoundLevelChange != null
            ? (_) => onSoundLevelChange()
            : null,
        listenOptions: listenOptions,
      );
      return true;
    } catch (e) {
      debugPrint('STT listen error with $localeId: $e');
      // If listen failed with locale, attempt fallback with ar_SA or en_US
      if (localeId != null && (localeId.contains('ar') || currentLang == 'darija' || currentLang == 'ar')) {
        try {
          debugPrint('STT: Retrying listen with ar_SA fallback...');
          final fallbackOptions = stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: false,
            partialResults: true,
            pauseFor: const Duration(seconds: 3),
            listenFor: const Duration(seconds: 30),
            localeId: 'ar_SA',
          );
          await _speech.listen(
            onResult: (result) {
              final words = result.recognizedWords;
              if (words.isNotEmpty) {
                _lastRecognizedWords = words;
                onResult(words);
              }
              if (result.finalResult && !_sessionEnded) {
                _sessionEnded = true;
                _isListening = false;
                onListeningEnded();
              }
            },
            onSoundLevelChange: onSoundLevelChange != null
                ? (_) => onSoundLevelChange()
                : null,
            listenOptions: fallbackOptions,
          );
          return true;
        } catch (e2) {
          debugPrint('STT retry error: $e2');
        }
      }
      _isListening = false;
      onError?.call(e.toString());
      return false;
    }
  }

  /// Stop listening. If [submitBuffer] is true and words were recognized,
  /// returns the last recognized words so the caller can submit them.
  Future<String?> stopListening({bool submitBuffer = false}) async {
    final buffered = _lastRecognizedWords;
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        debugPrint('Error stopping speech: $e');
      }
      _isListening = false;
    }
    _sessionEnded = true;
    if (submitBuffer && buffered.trim().isNotEmpty) {
      return buffered.trim();
    }
    return buffered.trim().isNotEmpty ? buffered.trim() : null;
  }

  Future<void> speak({
    required String text,
    required String lang,
    VoidCallback? onComplete,
  }) async {
    if (_isListening) {
      await stopListening();
    }
    await stopSpeaking();

    String ttsLang = 'ar-SA';
    if (lang == 'en') {
      ttsLang = 'en-US';
    } else if (lang == 'fr') {
      ttsLang = 'fr-FR';
    } else if (lang == 'darija') {
      // Android / iOS TTS engines support standard Arabic phonetic vocalization of Darija
      ttsLang = 'ar-SA';
    } else {
      ttsLang = 'ar-SA';
    }

    try {
      await _tts.setLanguage(ttsLang);
      await _tts.setPitch(_pitch);
      await _tts.setSpeechRate(_speechRate);
      _isSpeaking = true;
      if (onComplete != null) {
        _tts.setCompletionHandler(() {
          _isSpeaking = false;
          onComplete();
        });
      }
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
  }
}
