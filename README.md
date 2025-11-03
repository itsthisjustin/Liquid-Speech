# Liquid Speech

**Liquid Speech** - Real-time speech-to-text transcription for Flutter on iOS and macOS using Apple's native SpeechAnalyzer API

A Flutter package that provides native iOS 26+ and macOS 26+ real-time speech-to-text transcription with graceful fallback support for older OS versions.

## Features

- ✅ Real-time speech-to-text transcription (iOS 26+, macOS 26+)
- ✅ Compiles on iOS 14+ and macOS 11+ for broad compatibility
- ✅ Raw transcript updates as the user speaks
- ✅ Simple, intuitive API with runtime availability checks
- ✅ Event-based architecture with streams
- ✅ Proper microphone permission handling
- ✅ Clean resource management and lifecycle handling

## Requirements

- **iOS**: Package compiles on iOS 14.0+ but only **functions** on iOS 26.0+
- **macOS**: Package compiles on macOS 11.0+ but only **functions** on macOS 26.0+
- **Flutter**: 3.9.0+
- **Dart**: 3.5.0+

⚠️ **Important:** This package uses Apple's SpeechAnalyzer API which is only available on iOS 26.0+ and macOS 26.0+. The package compiles on iOS 14+ and macOS 11+ but will return `false` from `isAvailable()` on earlier versions. Use runtime checks to conditionally use the feature.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  liquid_speech: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Conditional Usage (iOS 14+ / macOS 11+)

This package can be safely added to apps targeting older iOS and macOS versions. Use runtime checks to conditionally use the SpeechAnalyzer API based on the device's OS version:

```dart
import 'package:liquid_speech/liquid_speech.dart';

class ConditionalSpeechService {
  late SpeechAnalyzerService _speechAnalyzer;

  Future<bool> initializeSpeechAnalyzer() async {
    _speechAnalyzer = SpeechAnalyzerService();

    // Check if speech analyzer is available on this device
    final isAvailable = await _speechAnalyzer.isAvailable();

    if (isAvailable) {
      print('✓ SpeechAnalyzer available (iOS 26+ / macOS 26+)');
      return true;
    } else {
      print('✗ SpeechAnalyzer not available (needs iOS 26+ or macOS 26+)');
      // Fall back to alternative STT solution
      return false;
    }
  }

  Future<void> transcribeAudio() async {
    final isAvailable = await _speechAnalyzer.isAvailable();

    if (!isAvailable) {
      // Use alternative speech-to-text service
      await _useAlternativeSTT();
      return;
    }

    // Use native SpeechAnalyzer
    final success = await _speechAnalyzer.startTranscription();
    if (success) {
      // Listen for transcription events
      _speechAnalyzer.transcriptionEvents.listen((event) {
        if (event.type == 'update') {
          print('Transcript: ${event.transcript}');
        }
      });
    }
  }

  Future<void> _useAlternativeSTT() async {
    // Implement fallback speech-to-text (e.g., Google Speech-to-Text, etc.)
    print('Using fallback speech-to-text service');
  }
}
```

### Best Practices

1. **Always check `isAvailable()`** before using the package
2. **Call it once at app startup** and cache the result
3. **Provide a graceful fallback** for older OS versions
4. **No conditional imports needed** - the package compiles everywhere

## Permissions

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to transcribe your speech</string>
```

### macOS

Add to `macos/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to transcribe your speech</string>
```

## Usage

### Basic Example

```dart
import 'package:liquid_speech/liquid_speech.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SpeechAnalyzerService _speechAnalyzer;
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    _speechAnalyzer = SpeechAnalyzerService();

    // Listen to transcription events
    _speechAnalyzer.transcriptionEvents.listen((event) {
      setState(() {
        if (event.type == 'update' && event.transcript != null) {
          _transcript = event.transcript!;
        }
      });
    });
  }

  @override
  void dispose() {
    _speechAnalyzer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await _speechAnalyzer.startTranscription();
    if (success) {
      print('Transcription started');
    }
  }

  Future<void> _stopRecording() async {
    final transcript = await _speechAnalyzer.stopTranscription();
    print('Final transcript: $transcript');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Analyzer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Transcript: $_transcript'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startRecording,
              child: const Text('Start'),
            ),
            ElevatedButton(
              onPressed: _stopRecording,
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Advanced: Handling Events

```dart
_speechAnalyzer.transcriptionEvents.listen((event) {
  switch (event.type) {
    case 'started':
      print('Transcription started');
      break;
    case 'update':
      print('Text: ${event.transcript}');
      print('Is final: ${event.isFinal}');
      print('Confidence: ${event.confidence}');
      break;
    case 'stopped':
      print('Transcription stopped. Final: ${event.transcript}');
      break;
    case 'error':
      print('Error: ${event.error}');
      break;
  }
});
```

### Advanced: Checking Availability

```dart
final available = await _speechAnalyzer.isAvailable();
if (!available) {
  print('Speech Analyzer not available on this device');
}
```

## API Reference

### `SpeechAnalyzerService`

#### Properties

- `Stream<TranscriptionEvent> transcriptionEvents` - Stream of transcription events
- `String currentTranscript` - The current raw transcript as it's being spoken

#### Methods

- `Future<bool> isAvailable()` - Check if speech analyzer is available
- `Future<bool> startTranscription()` - Start real-time transcription
- `Future<String?> stopTranscription()` - Stop transcription and return final transcript
- `void dispose()` - Clean up resources

### `TranscriptionEvent`

```dart
class TranscriptionEvent {
  String type;                 // 'started', 'update', 'stopped', 'error'
  String? transcript;          // Transcribed text
  bool isFinal;               // Whether transcript is final
  double confidence;          // Confidence score (0.0-1.0)
  DateTime timestamp;         // When the event occurred
  String? error;              // Error message if type == 'error'
}
```

## Transcript Flow

1. User starts recording by calling `startTranscription()`
2. Microphone permission is requested if needed
3. As user speaks, `transcriptionUpdate` events are emitted with partial transcripts
4. When user pauses/stops, `isFinal: true` is set
5. `stopTranscription()` is called to finalize and get the complete transcript

## Example App

Run the example app to see the package in action:

```bash
cd packages/liquid_speech/example
flutter run
```

The example demonstrates:
- Starting/stopping transcription
- Real-time transcript updates
- Event logging
- Error handling
- UI state management

## Architecture

### Dart Side

```
SpeechAnalyzerService
├── Method Channel (com.liquid.speech/native)
├── Event Stream (TranscriptionEvent)
└── State Management
```

### Native Side

**iOS/macOS:**
```
SpeechAnalyzerPlugin (auto-registered via Flutter plugin system)
├── Static Handler Storage (keeps handler alive for lifetime of app)
└── SpeechAnalyzerHandler
    ├── AVAudioEngine (audio capture)
    ├── SpeechAnalyzer API
    ├── SpeechTranscriber (speech-to-text)
    └── AsyncStream<AnalyzerInput> (audio streaming)
```

#### Plugin Registration

The plugin automatically registers on app startup via the Flutter plugin system and stores both the handler and channel as static variables. This ensures they remain alive for the entire app lifecycle and are available to handle method calls from the Dart side.

## Known Limitations

1. **Single Language**: Currently hardcoded to `en_US`. Future versions will support language selection.
2. **No Confidence Scores**: The native API doesn't expose confidence values, so all scores are 0.0.
3. **iOS/macOS Only**: Android support is not currently implemented.

## Troubleshooting

### "Microphone permission denied"

Add the microphone permission to your Info.plist file (see Permissions section above).

### No transcription events received

Make sure you:
1. Have added the package to `pubspec.yaml`
2. Called `flutter pub get`
3. Have microphone permissions granted
4. Are listening to `transcriptionEvents` stream before starting transcription

### App crashes on startup

This usually means the native plugin files weren't properly copied. Try:
```bash
flutter clean
flutter pub get
flutter run
```

## Contributing

Contributions are welcome! Please file issues and submit pull requests on GitHub.

## License

MIT

## References

- [Apple SpeechAnalyzer Documentation](https://developer.apple.com/documentation/speech/speechanalyzer)
- [AVAudioEngine Guide](https://developer.apple.com/documentation/avfoundation/avaudioengine)
- [Flutter Plugin Development](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
