# Speech Analyzer Package - Complete Overview

**Version:** 0.1.0
**Status:** Ready for production use
**Platform Support:**
- Compiles on iOS 14.0+ and macOS 11.0+
- Functions on iOS 26.0+ and macOS 26.0+
**Framework:** Apple's native SpeechAnalyzer API + Flutter
**Compatibility:** Can be added to any app with iOS 14+ / macOS 11+ targets. Uses runtime checks for iOS 26+ / macOS 26+ functionality.

---

## What is This Package?

A reusable, production-ready Flutter package that provides **real-time speech-to-text transcription** for iOS and macOS using Apple's native SpeechAnalyzer API (available in iOS 26+ and macOS 26+).

The package returns **raw transcripts** without any post-processing, making it flexible for different use cases:
- Use transcripts directly in your app
- Clean up with your own AI service
- Integrate with different speech processing pipelines

### 🎯 Key Benefit: Broad Compatibility with Graceful Degradation

This package is designed to work in apps supporting older iOS/macOS versions:
- Package **compiles** on iOS 14+ and macOS 11+
- Speech transcription **only works** on iOS 26+ and macOS 26+
- Apps can check `isAvailable()` at runtime and provide fallbacks
- **No conditional imports needed** - single codebase supports all versions

---

## Package Contents

### 📁 Directory Structure

```
speech_analyzer/
├── android/                      # Placeholder for future Android support
├── ios/
│   ├── Classes/
│   │   ├── SpeechAnalyzerPlugin.swift
│   │   └── SpeechAnalyzerHandler.swift
│   └── speech_analyzer.podspec
├── macos/
│   ├── Classes/
│   │   ├── SpeechAnalyzerPlugin.swift
│   │   └── SpeechAnalyzerHandler.swift
│   └── speech_analyzer.podspec
├── lib/
│   ├── speech_analyzer.dart                      # Main export
│   └── src/
│       ├── models/
│       │   └── transcription_event.dart          # Event model
│       └── services/
│           └── speech_analyzer_service.dart      # Main service class
├── example/
│   ├── lib/main.dart                            # Complete working example
│   └── pubspec.yaml
├── test/                                         # Future: Unit tests
├── pubspec.yaml                                 # Package definition
├── README.md                                    # Usage documentation
├── CHANGELOG.md                                 # Version history
├── LICENSE                                      # MIT License
├── analysis_options.yaml                        # Linter configuration
└── PACKAGE_OVERVIEW.md                          # This file
```

### 📄 Key Files

#### `lib/src/models/transcription_event.dart`
- **Purpose:** Data model for transcription events
- **Contains:** Event type, transcript, timestamp, error info
- **Usage:** Received via `SpeechAnalyzerService.transcriptionEvents` stream

#### `lib/src/services/speech_analyzer_service.dart`
- **Purpose:** Main service class that bridges Dart ↔ Native
- **Methods:**
  - `startTranscription()` - Begin capturing speech
  - `stopTranscription()` - End capture and return transcript
  - `isAvailable()` - Check if API is supported
  - `dispose()` - Clean up resources
- **Properties:**
  - `transcriptionEvents` - Stream of events
  - `currentTranscript` - Current text being spoken

#### `ios/Classes/SpeechAnalyzerPlugin.swift`
- **Purpose:** iOS plugin entry point (auto-registered via Flutter plugin system)
- **Key Feature:** Stores handler and channel as static variables to keep them alive
- **Behavior:** Automatically invoked on app startup via `register(with:)` static method

#### `ios/Classes/SpeechAnalyzerHandler.swift`
- **Purpose:** iOS native implementation
- **Uses:** Apple's `SpeechAnalyzer`, `SpeechTranscriber`, `AVAudioEngine`
- **Key Responsibilities:**
  - Audio capture via AVAudioEngine
  - Real-time transcription streaming
  - Format conversion and buffer management
  - Method channel communication with Dart

#### `macos/Classes/SpeechAnalyzerPlugin.swift`
- **Purpose:** macOS plugin entry point (auto-registered via Flutter plugin system)
- **Key Feature:** Stores handler and channel as static variables to keep them alive
- **Behavior:** Automatically invoked on app startup via `register(with:)` static method

#### `macos/Classes/SpeechAnalyzerHandler.swift`
- **Purpose:** macOS native implementation
- **Differences from iOS:**
  - No audio session category configuration (macOS-specific)
  - Same underlying transcription logic
  - Same plugin registration pattern

#### `example/lib/main.dart`
- **Purpose:** Complete working example app
- **Shows:**
  - Service initialization
  - Event listening
  - Start/stop recording
  - Real-time UI updates
  - Error handling
  - Event logging

---

## How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Dart Code (AudioRecordingButton, etc.)               │   │
│  │                                                      │   │
│  │ - Call: SpeechAnalyzerService.startTranscription()   │   │
│  │ - Listen: .transcriptionEvents.listen()              │   │
│  │ - Call: SpeechAnalyzerService.stopTranscription()    │   │
│  └──────────────────────────────────────────────────────┘   │
│            ↕ (Method Channel)                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ speech_analyzer Package (Dart layer)                 │   │
│  │ - SpeechAnalyzerService                              │   │
│  │ - TranscriptionEvent model                           │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
        ↕
┌─────────────────────────────────────────────────────────────┐
│                    Platform Layer                            │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ iOS/macOS Native Code (Swift)                         │   │
│  │                                                      │   │
│  │ - SpeechAnalyzerHandler                              │   │
│  │ - Uses: SpeechAnalyzer, SpeechTranscriber APIs       │   │
│  │ - Audio: AVAudioEngine                               │   │
│  │ - Sends events back via Method Channel               │   │
│  └──────────────────────────────────────────────────────┘   │
│            ↕ (Method Channel: com.speech.analyzer/native)   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Apple Native APIs                                     │   │
│  │ - SpeechAnalyzer                                      │   │
│  │ - SpeechTranscriber                                   │   │
│  │ - AVAudioEngine                                       │   │
│  │ - Microphone Hardware                                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow: Recording Speech

```
1. User taps "Start" button
   └─> Call: await speechAnalyzer.startTranscription()

2. Native side:
   ├─> Request microphone permission
   ├─> Create SpeechTranscriber + SpeechAnalyzer
   ├─> Setup AVAudioEngine for audio capture
   ├─> Create AsyncStream for audio input
   ├─> Start listening to transcriber.results
   └─> Send "transcriptionStarted" event

3. User speaks: "Hello world"
   ├─> AVAudioEngine captures audio
   ├─> Audio fed to SpeechAnalyzer via AsyncStream
   ├─> SpeechAnalyzer processes continuously
   ├─> SpeechTranscriber outputs:
   │   ├─> "Hel" (partial, isFinal: false)
   │   ├─> "Hello" (partial, isFinal: false)
   │   ├─> "Hello wor" (partial, isFinal: false)
   │   ├─> "Hello world" (partial, isFinal: false)
   │   └─> "Hello world" (final, isFinal: true)
   │
   ├─> Each result sent via Method Channel:
   │   └─> TranscriptionEvent(
   │         type: 'update',
   │         transcript: "Hello world",
   │         isFinal: false,
   │         ...
   │       )
   │
   └─> Dart receives event:
       └─> StreamController broadcasts to listeners
           └─> UI updates in real-time

4. User stops recording
   └─> Call: final transcript = await speechAnalyzer.stopTranscription()

5. Native side cleanup:
   ├─> Stop AVAudioEngine
   ├─> Finalize SpeechAnalyzer
   ├─> Cancel transcriber task
   ├─> Reset all state
   └─> Send "transcriptionStopped" event

6. Return final transcript to Dart
   └─> Use in your app (directly or with cleanup)
```

### Method Channel Communication

**Channel Name:** `com.speech.analyzer/native`

**Methods Called from Dart:**
- `startRealTimeTranscription()` - Initiate transcription
- `stopTranscription()` - Stop and finalize
- `isAvailable()` - Check support

**Methods Called from Native:**
- `onTranscriptionEvent(data)` - Send events to Dart

**Event Data Structure:**
```dart
{
  'event': String,              // 'started', 'update', 'stopped', 'error'
  'transcript': String?,        // Text (for update/stopped)
  'isFinal': bool?,            // Is final (for update)
  'error': String?,            // Error message (for error)
  'timestamp': double          // Unix timestamp
}
```

---

## Integration Points

### 1. Plugin Registration (Automatic)

The native plugins auto-register via Flutter's plugin system:
- iOS: Uses `FlutterPlugin` protocol
- macOS: Uses `FlutterPlugin` protocol

No manual setup in AppDelegate required.

### 2. Method Channel

Both iOS and macOS create the same method channel:
```swift
let channel = FlutterMethodChannel(
  name: "com.speech.analyzer/native",
  binaryMessenger: ...
)
```

### 3. Permission Handling

The package requests permissions automatically:
```swift
AVAudioApplication.requestRecordPermission { granted in
  // Handle permission response
}
```

Users can grant/deny at the system prompt.

---

## Performance Characteristics

### Memory
- Audio buffers: 4KB per buffer (4096 samples)
- Minimal overhead from SpeechAnalyzer API
- Proper cleanup on stop

### CPU
- Real-time transcription doesn't block main thread
- Audio processing on background thread
- Efficient format conversion

### Battery
- Microphone usage: Minimal drain (speech-only, not continuous)
- API is optimized for real-time use
- Recommend stopping when not in use

### Network
- All processing is local (on-device)
- No network calls from the package itself
- Your app can make additional calls to AI services if needed

---

## Testing the Package

### Unit Testing
- Mock `MethodChannel` calls
- Test event stream emissions
- Test state management

### Integration Testing
- Run example app: `flutter run -d macos` or `flutter run -d ios`
- Manually test start/stop
- Test with various speech patterns and accents

### Manual Testing Checklist
- [ ] Start recording - see "transcriptionStarted" event
- [ ] Speak clearly - see real-time transcript updates
- [ ] Wait for silence - see isFinal=true event
- [ ] Stop recording - get final transcript
- [ ] Deny permission - see error event
- [ ] Rapid start/stop - no crashes
- [ ] Multiple recordings - clean state each time

---

## Customization

### Using with Your AI Service

```dart
final speechAnalyzer = SpeechAnalyzerService();
final aiService = MyAIService();

// Get raw transcript
final rawTranscript = await speechAnalyzer.stopTranscription();

// Clean with your AI
final cleaned = await aiService.cleanupTranscript(rawTranscript);

// Use cleaned version
widget.onSend!(cleaned);
```

### Custom Event Handling

```dart
speechAnalyzer.transcriptionEvents.listen((event) {
  if (event.type == 'error') {
    _showErrorDialog(event.error);
  } else if (event.isFinal) {
    _markAsFinalized();
  }
});
```

### Language Support (Future)

Currently hardcoded to `en_US`. To add language support:
1. Make locale configurable in `SpeechAnalyzerService`
2. Pass to native side via method parameter
3. Update SpeechTranscriber initialization

---

## Publishing to pub.dev

To publish this package publicly:

1. **Verify Quality**
   ```bash
   dart analyze          # Check for issues
   flutter test          # Run tests (when added)
   flutter test test/    # Test coverage
   ```

2. **Update Files**
   - Verify `pubspec.yaml` has correct info
   - Update `CHANGELOG.md` with new version
   - Ensure `README.md` is complete
   - Check `LICENSE` file

3. **Publish**
   ```bash
   flutter pub publish
   ```

4. **After Publishing**
   - Update Amber-Flutter's dependency:
     ```yaml
     speech_analyzer: ^0.1.0
     ```
   - Remove local path dependency
   - Test with pub.dev version

---

## Future Enhancements

### Short-term
- [ ] Add configurable language selection
- [ ] Add unit tests
- [ ] Add widget examples

### Medium-term
- [ ] Android implementation using Google Speech-to-Text
- [ ] Web implementation (if possible)
- [ ] Streaming results directly to server
- [ ] Audio file transcription

### Long-term
- [ ] Multi-language support
- [ ] Custom vocabulary/dictionary
- [ ] Speaker identification
- [ ] Audio quality metrics

---

## Troubleshooting

### Common Issues

**"Method channel not found"**
- Run `flutter clean && flutter pub get`
- Rebuild app
- Check plugin is registered in pubspec.yaml

**"Microphone permission denied"**
- Grant permission in iOS/macOS Settings
- Ensure Info.plist has NSMicrophoneUsageDescription

**"No transcription events"**
- Verify service initialized before starting
- Check stream listener created before start
- Confirm microphone permission granted
- Check method channel name matches

**"Transcription cuts off"**
- Ensure stopTranscription() is called
- Check that async/await is used correctly
- Verify audio engine isn't stopped prematurely

### Debug Logging

Add print statements to diagnose:

```dart
// In SpeechAnalyzerService
print('[SpeechAnalyzer] Starting transcription');
print('[SpeechAnalyzer] Received event: ${event.type}');
print('[SpeechAnalyzer] Current transcript: ${currentTranscript}');
```

---

## Conditional Usage: Supporting iOS 14+ and macOS 11+

### Why Conditional Usage?

This package can be added to any Flutter app targeting iOS 14+ or macOS 11+. However, the SpeechAnalyzer API is only available on iOS 26+ and macOS 26+. Here's how to gracefully handle both scenarios:

### Implementation Pattern

```dart
import 'package:speech_analyzer/speech_analyzer.dart';

class SpeechService {
  late SpeechAnalyzerService _speechAnalyzer;
  bool _isAvailable = false;

  // Initialize at app startup
  Future<void> initialize() async {
    _speechAnalyzer = SpeechAnalyzerService();

    // Check if SpeechAnalyzer API is available
    _isAvailable = await _speechAnalyzer.isAvailable();

    if (_isAvailable) {
      print('✓ Using native SpeechAnalyzer (iOS 26+ / macOS 26+)');
    } else {
      print('✗ SpeechAnalyzer not available, will use fallback');
    }
  }

  // Use with fallback
  Future<String?> transcribeAudio() async {
    if (!_isAvailable) {
      return await _useFallbackSTT();
    }

    try {
      final success = await _speechAnalyzer.startTranscription();
      if (!success) {
        return await _useFallbackSTT();
      }

      String finalTranscript = '';

      // Listen to transcript updates
      final subscription = _speechAnalyzer.transcriptionEvents.listen((event) {
        if (event.type == 'update' && event.transcript != null) {
          finalTranscript = event.transcript!;
        }
      });

      // User speaks... when done:
      final transcript = await _speechAnalyzer.stopTranscription();
      await subscription.cancel();

      return transcript;
    } catch (e) {
      print('Error using SpeechAnalyzer: $e');
      return await _useFallbackSTT();
    }
  }

  // Implement your fallback (e.g., Google Speech-to-Text, etc.)
  Future<String?> _useFallbackSTT() async {
    print('Using fallback speech-to-text service');
    // TODO: Implement alternative STT service
    return null;
  }
}
```

### Best Practices

1. **Initialize once at app startup**
   ```dart
   // In your main.dart or app initialization
   final speechService = SpeechService();
   await speechService.initialize();
   ```

2. **Cache the availability check**
   - Call `isAvailable()` once at startup
   - Store the result
   - Don't call it repeatedly (it's relatively fast but unnecessary)

3. **Always provide a fallback**
   - Have an alternative STT service ready
   - Users on iOS 14-25 / macOS 11-25 need this
   - Users whose devices deny permissions need this

4. **No conditional imports needed**
   - The package compiles everywhere
   - Just use runtime checks with `isAvailable()`
   - Single codebase, flexible deployment

### Testing on Different OS Versions

**For testing availability on various iOS versions:**
```bash
# Test on iOS 26+ (should have SpeechAnalyzer)
flutter run -d "iPhone 16 Pro"

# Test on iOS 14 simulator (should fall back gracefully)
flutter run -d "iPhone 15"
```

**For testing availability on various macOS versions:**
```bash
# Test on macOS 14+ (Sonoma and later - has SpeechAnalyzer)
flutter run -d macos

# Pre-release: Test fallback paths
```

---

## Resources

- [Apple SpeechAnalyzer API](https://developer.apple.com/documentation/speech/speechanalyzer)
- [AVAudioEngine Guide](https://developer.apple.com/documentation/avfoundation/avaudioengine)
- [Flutter Plugin Development](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
- [Method Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)

---

## License

MIT License - See LICENSE file

---

## Support

For issues, questions, or contributions:
1. Check the [README.md](README.md) for common questions
2. Review the [example app](example/) for usage examples
3. Check existing issues on GitHub
4. File a new issue with reproduction steps

---

**Version:** 0.1.0
**Last Updated:** November 2, 2025
**Maintainer:** CleftAI
**Status:** Production Ready ✅
