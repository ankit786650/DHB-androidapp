import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class AIAgent {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final Function(int) onNavigate;
  final Function(String) onFeedback;
  final Function() onLogout;
  final Function() onShowAnalytics;
  final Function() onShowHealthQR;

  static const String _agentName = 'रिंकी के पापा';
  static const String _developerName = 'शुभम';
  static const String _developerInfo = 'मुझे शुभम ने बनाया है';

  bool _isActive = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  Timer? _inactivityTimer;
  Position? _currentPosition;
  Map<String, dynamic> _healthMetrics = {};
  String? _healthQRData;

  static final Map<int, Map<String, dynamic>> _screenCommands = {
    0: {
      'keywords': ['डैशबोर्ड', 'dashboard', 'मुख्य', 'होम'],
      'response': 'डैशबोर्ड दिखा रही हूँ',
    },
    1: {
      'keywords': ['दवा', 'मेडिसिन', 'दवाइयाँ'],
      'response': 'आपकी दवाइयों की जानकारी',
    },
    2: {
      'keywords': ['डॉक्टर', 'अपॉइंटमेंट'],
      'response': 'डॉक्टर से जुड़ी जानकारी',
    },
    3: {
      'keywords': ['डॉक्यूमेंट', 'रिपोर्ट'],
      'response': 'आपके दस्तावेज़ यहाँ हैं',
    },
    4: {
      'keywords': ['अस्पताल', 'हॉस्पिटल', 'नजदीकी'],
      'response': 'नजदीकी अस्पतालों की जानकारी',
    },
  };

  late final Map<String, List<String>> _conversationPhrases;

  AIAgent({
    required this.onNavigate,
    required this.onFeedback,
    required this.onLogout,
    required this.onShowAnalytics,
    required this.onShowHealthQR,
  }) {
    _initializeConversationPhrases();
  }

  void _initializeConversationPhrases() {
    _conversationPhrases = {
      'greeting': [
        'नमस्ते! मैं $_agentName हूँ',
        'हैलो! $_agentName आपकी सहायक है',
      ],
      'farewell': ['अलविदा!', 'जल्द ही फिर मिलेंगे'],
      'help': [
        'मैं आपकी मदद कर सकती हूँ - समय, तारीख, स्थान, स्वास्थ्य विश्लेषण, QR कोड, डॉक्टर, दवा और अस्पताल की जानकारी में',
      ],
      'confused': ['माफ कीजिए, समझ नहीं आया', 'कृपया फिर से कहें'],
      'acknowledge': ['ठीक है!', 'जैसा आप कहें'],
      'identity': ['मैं $_agentName हूँ', 'मुझे $_developerName ने बनाया है'],
      'creator': [_developerInfo],
      'time': ['वर्तमान समय है', 'अभी समय है'],
      'date': ['आज की तारीख है', 'वर्तमान तारीख है'],
      'location': ['आपका वर्तमान स्थान है', 'आपकी लोकेशन है'],
      'analytics': [
        'आपके स्वास्थ्य विश्लेषण दिखा रही हूँ',
        'स्वास्थ्य आंकड़े प्रदर्शित कर रही हूँ',
      ],
      'qrcode': [
        'आपका स्वास्थ्य QR कोड दिखा रही हूँ',
        'QR कोड तैयार कर रही हूँ',
      ],
      'health_status': _getHealthStatusPhrases(),
    };
  }

  List<String> _getHealthStatusPhrases() {
    return [
      'आपकी हृदय गति ${_healthMetrics['heart_rate'] ?? '--'} है',
      'रक्तचाप ${_healthMetrics['blood_pressure'] ?? '--'} है',
      'ऑक्सीजन स्तर ${_healthMetrics['oxygen_level'] ?? '--'} है',
    ];
  }

  Future<void> initialize() async {
    try {
      final micStatus = await Permission.microphone.request();
      final locationStatus = await Permission.location.request();

      if (!micStatus.isGranted || !locationStatus.isGranted) {
        throw Exception('Permissions not granted');
      }

      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!available) throw Exception('Speech recognition unavailable');

      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5); // faster speaking speed
      await _flutterTts.setVolume(1.0);

      // Set Indian female voice if available
      final voices = await _flutterTts.getVoices;
      final femaleIndianVoice = voices.firstWhere(
        (voice) =>
            voice.toString().contains('hi-in') &&
            voice.toString().toLowerCase().contains('female'),
        orElse: () => null,
      );
      if (femaleIndianVoice != null) {
        await _flutterTts.setVoice(femaleIndianVoice);
      }

      await _getCurrentLocation();
    } catch (e) {
      if (kDebugMode) print('Initialization error: $e');
      rethrow;
    }
  }

  Future<void> setAgentActive(bool active) async {
    if (_isActive == active) return;
    _isActive = active;

    if (active) {
      await _greetUser();
    } else {
      await _stopListening();
      await _speak(_getRandomPhrase('farewell'));
    }
  }

  Future<void> updateHealthMetrics(Map<String, dynamic> metrics) async {
    _healthMetrics = metrics;
    _conversationPhrases['health_status'] = _getHealthStatusPhrases();
  }

  Future<void> updateHealthQR(String qrData) async {
    _healthQRData = qrData;
  }

  Future<void> _greetUser() async {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'सुप्रभात'
        : hour < 17
        ? 'नमस्ते'
        : 'शुभ संध्या';
    await _speak('$greeting! $_agentName आपकी सेवा में हाज़िर है।');
    _startContinuousListening();
  }

  Future<void> _startContinuousListening() async {
    if (!_isActive || _isListening || _isSpeaking) return;
    _isListening = true;
    _resetInactivityTimer();
    onFeedback('सुन रही हूँ...');

    await _speech.listen(
      localeId: 'hi-IN',
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
      onSoundLevelChange: (level) => _resetInactivityTimer(),
      onResult: (result) {
        _resetInactivityTimer();
        if (result.finalResult) {
          _processCommand(result.recognizedWords.trim().toLowerCase());
        }
      },
    );
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      if (_isActive && !_isSpeaking) {
        _speak('क्या मैं आपकी और किसी बात में मदद कर सकती हूँ?');
      }
    });
  }

  Future<void> _stopListening() async {
    _inactivityTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      onFeedback('');
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' && _isActive && !_isSpeaking) {
      _startContinuousListening();
    }
  }

  void _onSpeechError(dynamic error) {
    if (_isActive) {
      Future.delayed(
        const Duration(milliseconds: 500),
        _startContinuousListening,
      );
    }
  }

  Future<void> _processCommand(String command) async {
    onFeedback('आपने कहा: $command');
    if (command.contains('विश्लेषण') ||
        command.contains('analytics') ||
        command.contains('आंकड़े')) {
      onShowAnalytics();
      await _speak(_getRandomPhrase('analytics'));
      return;
    }
    if (command.contains('qr') ||
        command.contains('कोड') ||
        command.contains('क्यूआर')) {
      if (_healthQRData != null) {
        onShowHealthQR();
        await _speak(_getRandomPhrase('qrcode'));
      } else {
        await _speak('स्वास्थ्य QR कोड उपलब्ध नहीं है');
      }
      return;
    }
    if (command.contains('स्वास्थ्य') ||
        command.contains('health') ||
        command.contains('हृदय') ||
        command.contains('रक्तचाप') ||
        command.contains('ऑक्सीजन')) {
      if (_healthMetrics.isNotEmpty) {
        await _speak(_getRandomPhrase('health_status'));
      } else {
        await _speak('स्वास्थ्य डेटा उपलब्ध नहीं है');
      }
      return;
    }
    if (command.contains('समय') || command.contains('time')) {
      await _speak(
        '${_getRandomPhrase('time')} ${DateFormat('hh:mm a').format(DateTime.now())}',
      );
      return;
    }
    if (command.contains('तारीख') || command.contains('date')) {
      await _speak(
        '${_getRandomPhrase('date')} ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
      );
      return;
    }
    if (command.contains('स्थान') ||
        command.contains('location') ||
        command.contains('जगह')) {
      await _getCurrentLocation();
      await _speak(
        '${_getRandomPhrase('location')} ${_currentPosition != null ? '${_currentPosition!.latitude.toStringAsFixed(2)}° उत्तर, ${_currentPosition!.longitude.toStringAsFixed(2)}° पूर्व' : 'स्थान जानकारी उपलब्ध नहीं है'}',
      );
      return;
    }
    if (command.contains('तुम्हारा नाम') || command.contains('तुम कौन')) {
      await _speak(_getRandomPhrase('identity'));
      return;
    }
    if (command.contains('किसने बनाया') || command.contains('developer')) {
      await _speak(_getRandomPhrase('creator'));
      return;
    }
    for (final entry in _screenCommands.entries) {
      if (entry.value['keywords'].any((kw) => command.contains(kw))) {
        onNavigate(entry.key);
        await _speak(entry.value['response']);
        return;
      }
    }
    if (command.contains('नमस्ते') || command.contains('hello')) {
      await _speak(_getRandomPhrase('greeting'));
      return;
    }
    if (command.contains('धन्यवाद') || command.contains('शुक्रिया')) {
      await _speak('आपका स्वागत है');
      return;
    }
    if (command.contains('मदद') || command.contains('help')) {
      await _speak(_getRandomPhrase('help'));
      return;
    }
    if (command.contains('बंद') ||
        command.contains('रुको') ||
        command.contains('stop')) {
      setAgentActive(false);
      return;
    }
    await _speak(_getRandomPhrase('confused'));
  }

  String _getRandomPhrase(String type) {
    final phrases = _conversationPhrases[type] ?? ['कृपया फिर से कहें'];
    return phrases[DateTime.now().millisecond % phrases.length];
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    _isSpeaking = true;
    await _stopListening();

    try {
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        if (_isActive) _startContinuousListening();
      });

      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) print('TTS error: $e');
      _isSpeaking = false;
      if (_isActive) _startContinuousListening();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _currentPosition = null;
    }
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _stopListening();
    _speech.stop();
    _flutterTts.stop();
  }
}
