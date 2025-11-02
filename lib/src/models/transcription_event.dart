/// Represents a transcription event from the speech analyzer.
class TranscriptionEvent {
  /// Event type: 'started', 'update', 'stopped', 'error'
  final String type;

  /// The transcribed text (for 'update' and 'stopped' events)
  final String? transcript;

  /// Whether this transcript is final (user has paused/stopped speaking)
  final bool isFinal;

  /// Confidence score from the speech recognizer (0.0-1.0)
  final double confidence;

  /// Timestamp when the event was generated
  final DateTime timestamp;

  /// Error message (for 'error' events)
  final String? error;

  TranscriptionEvent({
    required this.type,
    this.transcript,
    this.isFinal = false,
    this.confidence = 0.0,
    required this.timestamp,
    this.error,
  });

  @override
  String toString() {
    return 'TranscriptionEvent(type: $type, transcript: $transcript, isFinal: $isFinal, timestamp: $timestamp, error: $error)';
  }
}
