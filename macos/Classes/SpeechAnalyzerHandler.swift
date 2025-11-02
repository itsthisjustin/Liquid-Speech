import Cocoa
import FlutterMacOS
import Speech
import AVFoundation

@available(macOS 26, *)
public class SpeechAnalyzerHandler {
    private var audioEngine: AVAudioEngine?
    private var speechAnalyzer: SpeechAnalyzer?
    private var speechTranscriber: SpeechTranscriber?
    private var analyzerFormat: AVAudioFormat?
    private var inputSequence: AsyncStream<AnalyzerInput>?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var recognizerTask: Task<Void, Error>?

    private weak var channel: FlutterMethodChannel?

    public init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    // MARK: - Public Methods

    public func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRealTimeTranscription":
            startRealTimeTranscription(result: result)
        case "stopTranscription":
            stopTranscription(result: result)
        case "isAvailable":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Real-time Transcription

    private func startRealTimeTranscription(result: @escaping FlutterResult) {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            guard let self = self else { return }

            if !granted {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "Microphone permission denied",
                    details: nil
                ))
                return
            }

            Task {
                do {
                    try await self.setupTranscriber()
                    result(nil)
                } catch {
                    result(FlutterError(
                        code: "SETUP_ERROR",
                        message: "Failed to setup transcriber: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
    }

    private func setupTranscriber() async throws {
        speechTranscriber = SpeechTranscriber(
            locale: Locale(identifier: "en_US"),
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )

        guard let transcriber = speechTranscriber else {
            throw NSError(domain: "SpeechAnalyzer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create transcriber"])
        }

        speechAnalyzer = SpeechAnalyzer(modules: [transcriber])

        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

        guard let analyzerFormat = analyzerFormat else {
            throw NSError(domain: "SpeechAnalyzer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get audio format"])
        }

        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()

        guard let inputSequence = inputSequence, let analyzer = speechAnalyzer else {
            throw NSError(domain: "SpeechAnalyzer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create input stream"])
        }

        try await analyzer.start(inputSequence: inputSequence)

        recognizerTask = Task {
            do {
                for try await result in transcriber.results {
                    let fullText = result.text.characters.reduce("") { $0 + String($1) }

                    var plainText = fullText
                    if let braceRange = fullText.range(of: "{") {
                        plainText = String(fullText[..<braceRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    }

                    self.sendMessage([
                        "event": "transcriptionUpdate",
                        "transcript": plainText,
                        "isFinal": result.isFinal,
                        "confidence": 0.0,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                }
            } catch {
                self.sendError("Transcription error: \(error.localizedDescription)")
            }
        }

        do {
            try setupAudioEngine(format: analyzerFormat)
            sendMessage(["event": "transcriptionStarted", "timestamp": Date().timeIntervalSince1970])
        } catch {
            throw NSError(domain: "SpeechAnalyzer", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to setup audio engine"])
        }
    }

    private func setupAudioEngine(format: AVAudioFormat) throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "SpeechAnalyzer", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio engine"])
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, audioTime in
            Task {
                await self?.streamAudioToTranscriber(buffer, targetFormat: format)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) async {
        guard let inputBuilder = inputBuilder else { return }

        let input: AnalyzerInput
        if buffer.format == targetFormat {
            input = AnalyzerInput(buffer: buffer)
        } else {
            guard let convertedBuffer = try? convertBuffer(buffer, to: targetFormat) else {
                return
            }
            input = AnalyzerInput(buffer: convertedBuffer)
        }

        inputBuilder.yield(input)
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let converter = AVAudioConverter(from: buffer.format, to: targetFormat)!
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: UInt32(Double(buffer.frameLength) * Double(targetFormat.sampleRate) / Double(buffer.format.sampleRate)))!

        var error: NSError?
        converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        if let error = error {
            throw error
        }

        return outputBuffer
    }

    private func stopTranscription(result: @escaping FlutterResult) {
        Task {
            do {
                audioEngine?.stop()
                audioEngine?.inputNode.removeTap(onBus: 0)

                inputBuilder?.finish()
                try await speechAnalyzer?.finalizeAndFinishThroughEndOfInput()
                recognizerTask?.cancel()

                audioEngine = nil
                inputSequence = nil
                inputBuilder = nil
                recognizerTask = nil
                speechAnalyzer = nil
                speechTranscriber = nil
                analyzerFormat = nil

                sendMessage(["event": "transcriptionStopped", "timestamp": Date().timeIntervalSince1970])
                result(nil)
            } catch {
                result(FlutterError(
                    code: "STOP_ERROR",
                    message: "Failed to stop transcription: \(error.localizedDescription)",
                    details: nil
                ))
            }
        }
    }

    // MARK: - Message Communication

    private func sendMessage(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod("onTranscriptionEvent", arguments: data)
        }
    }

    private func sendError(_ message: String) {
        sendMessage([
            "event": "transcriptionError",
            "error": message,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}
