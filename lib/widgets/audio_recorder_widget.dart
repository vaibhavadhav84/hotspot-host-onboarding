// lib/widgets/audio_recorder_widget.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String path) onRecordingComplete;
  final Function()? onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderReady = false;
  bool _isRecording = false;
  String? _path;
  double _dbLevel = 0.0;
  StreamSubscription? _recorderSub;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _recorder.openRecorder();
      _isRecorderReady = true;
      setState(() {});
    }
  }

  Future<String> _tempFilePath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
  }

  Future<void> _startRecording() async {
    if (!_isRecorderReady) return;
    final path = await _tempFilePath();
    _path = path;
    await _recorder.startRecorder(toFile: path);
    _recorderSub = _recorder.onProgress?.listen((e) {
      setState(() {
        _dbLevel = (e.decibels ?? -40.0) + 40.0;
      });
    });
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording({bool keep = true}) async {
    await _recorder.stopRecorder();
    _recorderSub?.cancel();
    setState(() => _isRecording = false);

    if (!keep && _path != null) {
      final file = File(_path!);
      if (await file.exists()) await file.delete();
      _path = null;
    } else if (_path != null) {
      widget.onRecordingComplete(_path!);
    }
  }

  Future<void> _cancelRecording() async {
    await _stopRecording(keep: false);
    widget.onCancel?.call();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _recorderSub?.cancel();
    super.dispose();
  }

  Widget _buildWaveform() {
    final bars = List.generate(8, (i) {
      final height = 8 + (_dbLevel / 2) * (0.3 + (i % 3) * 0.1);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 6,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: Colors.white,
      );
    });
    return Row(mainAxisSize: MainAxisSize.min, children: bars);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            if (_isRecording) {
              await _stopRecording();
            } else {
              await _startRecording();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.redAccent : const Color(0xff1f1f1f),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (_isRecording) _buildWaveform(),
        if (_isRecording)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: _cancelRecording,
          ),
      ],
    );
  }
}
