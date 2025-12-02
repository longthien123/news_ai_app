import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service để quản lý Text-to-Speech
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentText;

  bool get isSpeaking => _isSpeaking;
  String? get currentText => _currentText;

  /// Khởi tạo TTS với cấu hình
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Lắng nghe các sự kiện trước
      _flutterTts.setStartHandler(() {
        print('TTS Start handler called');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        print('TTS Completion handler called');
        _isSpeaking = false;
        _currentText = null;
      });

      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        _isSpeaking = false;
        _currentText = null;
      });

      _flutterTts.setCancelHandler(() {
        print('TTS Cancel handler called');
        _isSpeaking = false;
        _currentText = null;
      });

      if (kIsWeb) {
        // Cấu hình cho web
        final languages = await _flutterTts.getLanguages;
        print('Available languages: $languages');
        
        final voices = await _flutterTts.getVoices;
        print('Available voices: $voices');

        // Thử cả vi-VN và vi
        try {
          await _flutterTts.setLanguage("vi-VN");
          print('Language set to vi-VN');
        } catch (e) {
          print('Failed to set vi-VN, trying vi: $e');
          await _flutterTts.setLanguage("vi");
        }
        
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSharedInstance(true);
      } else {
        // Cấu hình cho mobile
        print('Configuring TTS for mobile...');
        
        // Đặt cấu hình trước
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        
        // Kiểm tra ngôn ngữ có sẵn
        try {
          final languages = await _flutterTts.getLanguages;
          print('Available languages on mobile: $languages');

          // Kiểm tra xem tiếng Việt có sẵn không
          final isVietnameseAvailable = await _flutterTts.isLanguageAvailable("vi-VN");
          print('Vietnamese (vi-VN) available: $isVietnameseAvailable');

          if (isVietnameseAvailable) {
            final result = await _flutterTts.setLanguage("vi-VN");
            print('Language set to vi-VN, result: $result');
          } else {
            // Thử với "vi" thay vì "vi-VN"
            final isViAvailable = await _flutterTts.isLanguageAvailable("vi");
            print('Vietnamese (vi) available: $isViAvailable');
            
            if (isViAvailable) {
              final result = await _flutterTts.setLanguage("vi");
              print('Language set to vi, result: $result');
            } else {
              // Fallback về tiếng Anh
              print('Vietnamese not available, using English (en-US)');
              await _flutterTts.setLanguage("en-US");
            }
          }
        } catch (e) {
          print('Error checking languages: $e');
          // Cố gắng set tiếng Việt anyway
          await _flutterTts.setLanguage("vi-VN");
        }

        // Android cần thêm thời gian để TTS engine sẵn sàng
        await Future.delayed(const Duration(seconds: 1));
      }

      _isInitialized = true;
      print('TTS initialized successfully for ${kIsWeb ? "web" : "mobile"}');
    } catch (e) {
      print('Error initializing TTS: $e');
      _isInitialized = false;
    }
  }

  /// Đọc văn bản
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      print('TTS not initialized, initializing now...');
      await initialize();
      
      // Đợi thêm một chút để đảm bảo TTS engine sẵn sàng
      if (!kIsWeb) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    try {
      // Kiểm tra lại xem đã khởi tạo thành công chưa
      if (!_isInitialized) {
        print('TTS initialization failed, cannot speak');
        return;
      }

      // Dừng bất kỳ TTS nào đang chạy
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      
      _currentText = text;
      _isSpeaking = true;
      
      print('Speaking text (${text.length} characters)...');
      
      // Android TTS có giới hạn ~4000 ký tự, chia nhỏ text nếu quá dài
      if (text.length > 3500) {
        print('Text too long, splitting into chunks...');
        await _speakInChunks(text);
      } else {
        final result = await _flutterTts.speak(text);
        print('TTS speak result: $result');
        
        if (result == 1) {
          print('TTS started speaking successfully');
        } else {
          print('TTS speak failed with result: $result');
          _isSpeaking = false;
        }
      }
    } catch (e) {
      print('Error speaking: $e');
      _isSpeaking = false;
      
      // Thử khởi tạo lại nếu có lỗi
      _isInitialized = false;
    }
  }

  /// Chia text thành các đoạn nhỏ và đọc tuần tự
  Future<void> _speakInChunks(String text) async {
    // Chia text theo câu (dấu chấm, chấm hỏi, chấm than)
    final sentences = text.split(RegExp(r'[.!?。！？]\s*'));
    final chunks = <String>[];
    String currentChunk = '';

    for (final sentence in sentences) {
      if (sentence.trim().isEmpty) continue;

      // Nếu thêm câu này vào chunk hiện tại vẫn < 3000 ký tự
      if (currentChunk.length + sentence.length < 3000) {
        currentChunk += '$sentence. ';
      } else {
        // Chunk đầy, lưu lại và bắt đầu chunk mới
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = '$sentence. ';
      }
    }

    // Thêm chunk cuối cùng
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    print('Split into ${chunks.length} chunks');

    // Đọc từng chunk
    for (int i = 0; i < chunks.length; i++) {
      if (!_isSpeaking) {
        print('TTS stopped by user');
        break;
      }

      print('Speaking chunk ${i + 1}/${chunks.length} (${chunks[i].length} chars)');
      final result = await _flutterTts.speak(chunks[i]);
      print('Chunk $i result: $result');

      if (result != 1) {
        print('Failed to speak chunk $i');
        _isSpeaking = false;
        break;
      }

      // Đợi chunk này đọc xong trước khi đọc chunk tiếp theo
      await Future.delayed(Duration(milliseconds: chunks[i].length * 50));
    }
  }

  /// Tạm dừng
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isSpeaking = false;
    } catch (e) {
      print('Error pausing: $e');
    }
  }

  /// Dừng hoàn toàn
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _currentText = null;
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  /// Thay đổi tốc độ đọc
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }

  /// Thay đổi cao độ giọng nói
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      print('Error setting pitch: $e');
    }
  }

  /// Thay đổi âm lượng
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Dispose
  Future<void> dispose() async {
    await stop();
  }
}
