Pod::Spec.new do |s|
  s.name             = 'liquid_speech'
  s.version          = '0.1.0'
  s.summary          = 'Real-time speech-to-text transcription for macOS'
  s.description      = <<-DESC
Liquid Speech: Real-time speech-to-text transcription using Apple's native SpeechAnalyzer API.
Supports macOS 26+ and compiles on macOS 11.0+ with graceful fallback on older versions.
Provides raw transcript updates with conditional availability checks.
                       DESC
  s.homepage         = 'https://github.com/cleftai/amber-flutter'
  s.license          = { :type => 'MIT' }
  s.author           = { 'CleftAI' => 'hello@cleftai.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '11.0'
  s.osx.deployment_target = '11.0'

  s.pod_target_xcconfig = { 'DEFINE_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
