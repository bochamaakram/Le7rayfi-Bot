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

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  Future<bool> get hasPermission => _speech.hasPermission;
  bool get isAvailable => _speechInitialized && _speech.isAvailable;
  String get lastRecognizedWords => _lastRecognizedWords;

  Future<void> init() async {
    // 1. Initialize TTS
    try {
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.85); // Natural conversational rate
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
    List<String> preferred;
    if (currentLang == 'en') {
      preferred = ['en_us', 'en_gb', 'en_ca', 'en_au', 'en'];
    } else if (currentLang == 'fr') {
      preferred = ['fr_fr', 'fr_ca', 'fr_be', 'fr'];
    } else {
      // Darija / Arabic
      preferred = ['ar_ma', 'ar_sa', 'ar_eg', 'ar_ae', 'ar'];
    }

    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) {
        debugPrint('STT: No locales returned by engine, will use system default.');
        return null;
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

    // Returning null tells SpeechToText to use the platform's default recognition locale
    return null;
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

    // Resolve best locale (null = system default)
    final localeId = await _resolveBestLocale(currentLang);
    debugPrint('STT: Starting listen session with locale: $localeId');

    _isListening = true;

    try {
      final listenOptions = stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation, // Optimal for conversational bot
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
      debugPrint('STT listen error: $e');
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
    if (submitBuffer && buffered.isNotEmpty) {
      final result = buffered;
      _lastRecognizedWords = '';
      return result;
    }
    _lastRecognizedWords = '';
    return null;
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

    String ttsLang = 'ar-XA';
    if (lang == 'en') {
      ttsLang = 'en-US';
    } else if (lang == 'fr') {
      ttsLang = 'fr-FR';
    } else {
      ttsLang = 'ar';
    }

    try {
      await _tts.setLanguage(ttsLang);
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
