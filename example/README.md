# Liquid Speech Example App

Example application demonstrating the **Liquid Speech** package for real-time speech-to-text transcription on iOS and macOS.

## Platform Support

- ✅ **iOS 26+** (compiles on iOS 14.0+)
- ✅ **macOS 26+** (compiles on macOS 11.0+)
- ❌ **Android** - Not supported
- ❌ **Web** - Not supported

## Features Demonstrated

The example app shows:

1. **Speech-to-text transcription** - Transcribe speech to final text
2. **Event handling** - Listening to transcription events (started, update, stopped, error)
3. **Status display** - Visual feedback during recording
4. **Event logging** - Complete record of all transcription events
5. **Microphone permissions** - Proper permission handling for iOS and macOS

## Running the Example

### iOS
```bash
flutter run -d <ios-device-or-simulator>
```

### macOS
```bash
flutter run -d macos
```

## How It Works

1. **Start Recording** - Tap the "Start" button to begin speech-to-text transcription
2. **Stop Recording** - Tap the "Stop" button to finalize transcription
3. **View Results** - Final transcript and event log displayed
4. **Event Log** - Complete record of all transcription events (started, update, stopped, error)

## Code Structure

- `lib/main.dart` - Complete example implementation
  - `MyApp` - Root widget with Material Design theme
  - `SpeechAnalyzerExample` - Main example screen with recording UI
  - Event handling and state management

## Permissions

The example includes microphone usage descriptions in:

- `ios/Runner/Info.plist` - iOS microphone permission
- `macos/Runner/Info.plist` - macOS microphone permission

Users will be prompted to grant microphone access on first use.

## Requirements

- Flutter 3.9.0 or later
- Dart 3.5.0 or later
- iOS 14.0+ or macOS 11.0+ (functions on iOS 26+ and macOS 26+ only)

## Troubleshooting

### "No transcription received"
- Ensure microphone permission is granted
- Check that OS is iOS 26+ or macOS 26+ (older versions require fallback implementation)
- Check `isAvailable()` to see if SpeechAnalyzer API is available

### "Permission denied"
- Grant microphone access when prompted by iOS/macOS
- Check app settings and enable microphone permission

### Build errors
- Run `flutter clean` and `flutter pub get`
- Ensure minimum iOS 14.0 and macOS 11.0 are set in your project

## Next Steps

To use Liquid Speech in your own app:

1. Add to your `pubspec.yaml`:
   ```yaml
   dependencies:
     liquid_speech: ^0.1.0
   ```

2. Add microphone permissions to Info.plist files

3. Import and use:
   ```dart
   import 'package:liquid_speech/liquid_speech.dart';

   final speechAnalyzer = SpeechAnalyzerService();
   ```

4. Check availability before using:
   ```dart
   if (await speechAnalyzer.isAvailable()) {
     // Use Liquid Speech
   } else {
     // Fallback for older OS versions
   }
   ```

See [Liquid Speech README](../README.md) for complete API documentation.
