# Changelog

All notable changes to Liquid Speech will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-02

### Added

- Initial release of **Liquid Speech** package
- Real-time speech-to-text transcription for iOS 26+ and macOS 26+
- Native SpeechAnalyzer API integration
- iOS 14+ and macOS 11+ compatibility with runtime availability checks
- `SpeechAnalyzerService` Dart service for easy API access
- `TranscriptionEvent` model for comprehensive event handling
- Event-based architecture with streams
- Microphone permission handling for both iOS and macOS
- Graceful fallback support for older OS versions
- Platform-specific implementation with `@available` attributes
- Example app demonstrating usage and best practices
- Comprehensive documentation and API reference
- Setup for publishing to pub.dev (iOS/macOS only)
