import 'dart:async';
import 'package:flutter/services.dart';
import '../models/transcription_event.dart';

/// Service for native iOS 26+ and macOS 26+ SpeechAnalyzer integration.
///
/// Provides real-time speech-to-text transcription with raw transcript updates
/// as the user speaks. Requires iOS 26+ or macOS 26+.
///
/// Example usage:
/// ```dart
/// final speechAnalyzer = SpeechAnalyzerService();
///
/// // Start transcription
/// await speechAnalyzer.startTranscription();
///
/// // Listen to transcription events
/// speechAnalyzer.transcriptionEvents.listen((event) {
///   if (event.type == 'update' && event.transcript != null) {
///     print('Transcript: ${event.transcript}');
///   }
/// });
///
/// // Stop and get final transcript
/// final transcript = await speechAnalyzer.stopTranscription();
/// ```
class SpeechAnalyzerService {
  static const platform = MethodChannel('com.liquid.speech/native');

  final StreamController<TranscriptionEvent> _eventController =
      StreamController<TranscriptionEvent>.broadcast();

  String _currentTranscript = '';
  bool _isTranscribing = false;

  SpeechAnalyzerService() {
    // Setup method channel listener for native events
    platform.setMethodCallHandler(_handleMethodCall);
  }

  /// Handles method calls from the native side.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onTranscriptionEvent') {
      final data = call.arguments as Map<dynamic, dynamic>;
      final event = data['event'] as String?;

      switch (event) {
        case 'transcriptionStarted':
          _addEvent(
            TranscriptionEvent(
              type: 'started',
              timestamp: DateTime.now(),
            ),
          );
          break;

        case 'transcriptionUpdate':
          final transcript = data['transcript'] as String? ?? '';
          final isFinal = data['isFinal'] as bool? ?? false;
          final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

          _currentTranscript = transcript;

          _addEvent(
            TranscriptionEvent(
              type: 'update',
              transcript: transcript,
              isFinal: isFinal,
              confidence: confidence,
              timestamp: DateTime.now(),
            ),
          );
          break;

        case 'transcriptionStopped':
          _addEvent(
            TranscriptionEvent(
              type: 'stopped',
              transcript: _currentTranscript,
              isFinal: true,
              timestamp: DateTime.now(),
            ),
          );
          break;

        case 'transcriptionError':
          final error = data['error'] as String? ?? 'Unknown error';
          _addEvent(
            TranscriptionEvent(
              type: 'error',
              error: error,
              timestamp: DateTime.now(),
            ),
          );
          break;
      }
    }
    return null;
  }

  /// Stream of transcription events.
  ///
  /// Events include:
  /// - 'started': Transcription started successfully
  /// - 'update': Partial or final transcript received
  /// - 'stopped': Transcription stopped
  /// - 'error': An error occurred during transcription
  Stream<TranscriptionEvent> get transcriptionEvents => _eventController.stream;

  /// Get the current raw transcript as it's being spoken.
  String get currentTranscript => _currentTranscript;

  /// Check if speech analyzer is available (iOS 26+ or macOS 26+).
  Future<bool> isAvailable() async {
    try {
      final result = await platform.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start real-time transcription.
  ///
  /// Requires microphone permissions. Will request permissions if not already granted.
  /// Returns true if transcription started successfully, false otherwise.
  Future<bool> startTranscription() async {
    try {
      if (_isTranscribing) {
        return false;
      }

      _isTranscribing = true;
      _currentTranscript = '';

      await platform.invokeMethod('startRealTimeTranscription');
      return true;
    } on PlatformException catch (e) {
      _isTranscribing = false;
      _addEvent(
        TranscriptionEvent(
          type: 'error',
          error: 'Failed to start transcription: ${e.message}',
          timestamp: DateTime.now(),
        ),
      );
      return false;
    }
  }

  /// Stop transcription and return the final raw transcript.
  ///
  /// Returns the complete transcript as a raw string.
  /// If transcription was not in progress, returns null.
  Future<String?> stopTranscription() async {
    try {
      if (!_isTranscribing) {
        return _currentTranscript;
      }

      _isTranscribing = false;

      await platform.invokeMethod('stopTranscription');

      final transcript = _currentTranscript;
      return transcript;
    } on PlatformException catch (e) {
      _isTranscribing = false;
      _addEvent(
        TranscriptionEvent(
          type: 'error',
          error: 'Failed to stop transcription: ${e.message}',
          timestamp: DateTime.now(),
        ),
      );
      return null;
    }
  }

  /// Add event to stream.
  void _addEvent(TranscriptionEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Clean up resources.
  void dispose() {
    _eventController.close();
  }
}
