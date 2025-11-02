import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liquid_speech/liquid_speech.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Analyzer Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SpeechAnalyzerExample(),
    );
  }
}

class SpeechAnalyzerExample extends StatefulWidget {
  const SpeechAnalyzerExample({Key? key}) : super(key: key);

  @override
  State<SpeechAnalyzerExample> createState() => _SpeechAnalyzerExampleState();
}

class _SpeechAnalyzerExampleState extends State<SpeechAnalyzerExample> {
  late SpeechAnalyzerService _speechAnalyzer;
  String _currentTranscript = '';
  String _finalTranscript = '';
  bool _isRecording = false;
  List<TranscriptionEvent> _events = [];
  StreamSubscription<TranscriptionEvent>? _transcriptionSubscription;
  late ScrollController _eventLogScrollController;

  @override
  void initState() {
    super.initState();
    _speechAnalyzer = SpeechAnalyzerService();
    _eventLogScrollController = ScrollController();
  }

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    _eventLogScrollController.dispose();
    _speechAnalyzer.dispose();
    super.dispose();
  }

  void _scrollEventLogToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_eventLogScrollController.hasClients) {
        _eventLogScrollController.jumpTo(
          _eventLogScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    final success = await _speechAnalyzer.startTranscription();
    if (success) {
      // Set up listener after starting transcription
      _transcriptionSubscription?.cancel();
      _transcriptionSubscription =
          _speechAnalyzer.transcriptionEvents.listen((event) {
        setState(() {
          _events.add(event);

          if (event.type == 'update' && event.transcript != null) {
            _currentTranscript = event.transcript!;
          } else if (event.type == 'stopped' && event.transcript != null) {
            _finalTranscript = event.transcript!;
          }
        });
        _scrollEventLogToBottom();
      });

      setState(() {
        _isRecording = true;
        _currentTranscript = '';
        _finalTranscript = '';
        _events.clear();
      });
    }
  }

  Future<void> _stopRecording() async {
    final transcript = await _speechAnalyzer.stopTranscription();
    setState(() {
      _isRecording = false;
      if (transcript != null) {
        _finalTranscript = transcript;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Analyzer Example'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Recording status
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red.shade50 : Colors.grey.shade100,
                  border: Border.all(
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isRecording)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      _isRecording ? 'Recording...' : 'Ready to record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isRecording ? Colors.red : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Final transcript
            if (_finalTranscript.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final Transcript:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _finalTranscript,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

            // Events log
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Event Log',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _eventLogScrollController,
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Text(
                                '[${event.type}] ${event.transcript ?? event.error ?? ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: event.type == 'error'
                                      ? Colors.red
                                      : Colors.grey.shade700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRecording ? null : _startRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('Start'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
