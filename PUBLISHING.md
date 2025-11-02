# Publishing Liquid Speech to pub.dev

## Pre-Publishing Checklist

- [ ] Version number in `pubspec.yaml` is correct
- [ ] CHANGELOG.md is updated with new features
- [ ] README.md is accurate and complete
- [ ] All platform-specific code is properly tested
- [ ] Example app builds and runs on both iOS and macOS
- [ ] Documentation links are correct

## Platform Support

**Liquid Speech is iOS and macOS only.**

- ✅ **iOS 14.0+** (functions on iOS 26+)
- ✅ **macOS 11.0+** (functions on macOS 26+)
- ❌ **Android** - Not supported
- ❌ **Web** - Not supported

The `pubspec.yaml` declares plugin support for iOS and macOS only.

## Publishing Steps

### 1. Verify Flutter and Dart versions
```bash
flutter --version
dart --version
```

Minimum requirements:
- Flutter: 3.9.0+
- Dart: 3.5.0+

### 2. Test the package

```bash
# Run the example app on iOS
flutter run -d "iPhone 16" --release

# Run the example app on macOS
flutter run -d macos --release

# Run any unit tests (if applicable)
flutter test
```

### 3. Check pub.dev requirements

```bash
# Analyze code for pub.dev compliance
flutter pub publish --dry-run
```

This will check:
- Platform compatibility declarations
- SDK constraints
- Dependencies
- Code analysis
- Documentation coverage

### 4. Create pub.dev account

If you don't have one:
1. Go to https://pub.dev
2. Create an account
3. Set up authentication with `pub.dev`

### 5. Publish to pub.dev

```bash
flutter pub publish
```

You'll be prompted to:
- Confirm you've read the pub.dev publishing agreement
- Verify the package contents

### 6. Verify publication

After publishing:
1. Visit https://pub.dev/packages/liquid_speech
2. Verify all information is correct
3. Check version history
4. Confirm documentation renders properly

## Version Bumping

Follow [Semantic Versioning](https://semver.org/):

- **Major** (x.0.0): Breaking changes
- **Minor** (0.x.0): New features, backward compatible
- **Patch** (0.0.x): Bug fixes

Update:
1. `pubspec.yaml` - version number
2. `CHANGELOG.md` - new entry with date
3. `example/pubspec.yaml` - if changing constraints

## Important Notes

### Platform-Specific Code

The package uses `@available(iOS 26, *)` and `@available(macOS 26, *)` attributes to ensure compilation works on iOS 14+ and macOS 11+ while runtime checks prevent crashes on older versions.

### No Android/Web Support

This package **only works on iOS and macOS** because:
1. Apple's SpeechAnalyzer API is iOS/macOS only
2. No alternative implementation available for other platforms
3. The `pubspec.yaml` explicitly declares iOS/macOS only

### Maintenance

After publishing, maintain the package by:
- Responding to pub.dev issue reports
- Keeping dependencies updated
- Testing with new Flutter/Dart releases
- Adding new features as Apple updates the SpeechAnalyzer API

## Resources

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Flutter Plugin Publishing](https://flutter.dev/docs/development/packages-and-plugins/publishing)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
