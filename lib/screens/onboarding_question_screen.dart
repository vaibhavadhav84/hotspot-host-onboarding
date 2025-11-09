// onboarding_question_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:assignment_app/screens/submission_success_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class OnboardingQuestionScreen extends StatefulWidget {
  const OnboardingQuestionScreen({super.key});

  @override
  State<OnboardingQuestionScreen> createState() =>
      _OnboardingQuestionScreenState();
}

class _OnboardingQuestionScreenState extends State<OnboardingQuestionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final int _maxChars = 600;

  // Audio
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecordingAudio = false;
  String? _audioFilePath;
  StreamSubscription? _recorderSubscription;
  double _dbLevel = 0.0; // used for waveform

  // Video
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  String? _videoFilePath;
  bool _isRecordingVideo = false;
  VideoPlayerController? _videoPlayerController;

  // Animation for Next button width
  late AnimationController _animController;
  late Animation<double> _buttonWidthAnim;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initCameras();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonWidthAnim = Tween<double>(begin: 1.0, end: 0.65).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _recorderSubscription?.cancel();
    _recorder.closeRecorder();
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      // handle permission denial gracefully
      return;
    }
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
    setState(() {});
  }

  Future<void> _initCameras() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      // handle permission denial gracefully
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  // ---------- AUDIO HANDLERS ----------
  Future<String> _tempFilePath(String ext) async {
    final dir = await getTemporaryDirectory();
    final file =
        '${dir.path}/onboard_${DateTime.now().millisecondsSinceEpoch}.$ext';
    return file;
  }

  Future<void> _startRecordingAudio() async {
    if (!_isRecorderInitialized) return;
    final path = await _tempFilePath('aac');
    _audioFilePath = path;
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
      bitRate: 64000,
      sampleRate: 44100,
    );
    _isRecordingAudio = true;

    // Listen for db levels if supported to animate waveform
    _recorderSubscription?.cancel();
    _recorderSubscription = _recorder.onProgress?.listen((event) {
      // event.decibels may be null on some platforms. fallback to duration-based animation
      final db = (event.decibels ?? -40.0) + 40.0; // normalize
      setState(() => _dbLevel = (db.clamp(0.0, 40.0) / 40.0));
    });

    setState(() {});
  }

  Future<void> _stopRecordingAudio({bool keep = true}) async {
    if (!_isRecorderInitialized) return;
    try {
      await _recorder.stopRecorder();
    } catch (e) {
      debugPrint('Stop recorder error: $e');
    }
    _recorderSubscription?.cancel();
    _isRecordingAudio = false;

    if (!keep && _audioFilePath != null) {
      final file = File(_audioFilePath!);
      if (await file.exists()) await file.delete();
      _audioFilePath = null;
    }

    // trigger ui change
    _updateNextButtonAnimation();
    setState(() {});
  }

  void _deleteAudio() async {
    if (_audioFilePath != null) {
      final f = File(_audioFilePath!);
      if (await f.exists()) await f.delete();
    }
    _audioFilePath = null;
    _updateNextButtonAnimation();
    setState(() {});
  }

  // ---------- VIDEO HANDLERS ----------
  Future<void> _startRecordingVideo() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final status = await Permission.camera.request();
    if (!status.isGranted) return;
    final path = await _tempFilePath('mp4');
    _videoFilePath = path;
    try {
      await _cameraController!.startVideoRecording();
      _isRecordingVideo = true;
      setState(() {});
    } catch (e) {
      debugPrint('Start video error: $e');
    }
  }

  Future<void> _stopRecordingVideo({bool keep = true}) async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      _isRecordingVideo = false;
      return;
    }
    try {
      final file = await _cameraController!.stopVideoRecording();
      _isRecordingVideo = false;

      // ✅ Use the path directly — no copying required
      _videoFilePath = file.path;

      debugPrint('✅ Video saved at: $_videoFilePath');

      // Initialize video player
      _videoPlayerController?.dispose();
      _videoPlayerController = VideoPlayerController.file(
        File(_videoFilePath!),
      );
      await _videoPlayerController!.initialize();
    } catch (e) {
      debugPrint('Stop video error: $e');
    }

    _updateNextButtonAnimation();
    setState(() {});
  }

  void _deleteVideo() async {
    if (_videoFilePath != null) {
      final f = File(_videoFilePath!);
      if (await f.exists()) await f.delete();
    }
    _videoFilePath = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _updateNextButtonAnimation();
    setState(() {});
  }

  // If user cancels while recording
  Future<void> _cancelRecordingAudio() async {
    await _stopRecordingAudio(keep: false);
  }

  Future<void> _cancelRecordingVideo() async {
    if (_isRecordingVideo) {
      try {
        await _cameraController!.stopVideoRecording();
      } catch (_) {}
      // delete the temporary file if exists
      _videoFilePath = null;
      _isRecordingVideo = false;
      _updateNextButtonAnimation();
      setState(() {});
    }
  }

  // ---------- UI helpers ----------
  void _updateNextButtonAnimation() {
    // If both audio and video recorded, expand the button else shrink
    final hasAsset = (_audioFilePath != null) || (_videoFilePath != null);
    if (hasAsset) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  String _shortFileName(String? path) {
    if (path == null) return '';
    return path.split('/').last;
  }

  // ---------- Final Submit ----------
  void _onNextPressed() {
    final text = _textController.text.trim();
    debugPrint('Text: $text');
    debugPrint('Audio: $_audioFilePath');
    debugPrint('Video: $_videoFilePath');

    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(const SnackBar(content: Text('State logged to console.')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Responses logged successfully!')),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubmissionSuccessScreen()),
      );
    });
  }

  // ---------- Waveform widget (simple animated bars for the recording) ----------
  Widget _buildWaveform(double level) {
    // create 8 bars with varying heights influenced by level and some animation randomness
    final bars = List.generate(8, (i) {
      // vary each bar a bit with index
      final factor = 0.3 + (i % 3) * 0.12;
      final height = 8.0 + (level * 40.0 * factor);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 6,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    });

    return Row(mainAxisSize: MainAxisSize.min, children: bars);
  }

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);

    // bottom area: either show record buttons or small tiles for recorded assets
    final _ = _audioFilePath == null || _videoFilePath == null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Container(
          height: 6,
          width: double.infinity,
          margin: const EdgeInsets.only(right: 48.0),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            widthFactor: 0.35,
            heightFactor: 1.0,
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            children: [
              // Title and subtitle
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Why do you want to host with us?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tell us about your intent and what motivates you to create experiences.',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Text field
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLength: _maxChars,
                  maxLines: null,
                  minLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '/Start typing here',
                    hintStyle: TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF171717),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    counterStyle: const TextStyle(color: Colors.white38),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // If there's audio recorded show a small tile
              if (_audioFilePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.tealAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Audio Recorded • ${_shortFileName(_audioFilePath)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        onPressed: _deleteAudio,
                        icon: const Icon(Icons.delete, color: Colors.white38),
                      ),
                    ],
                  ),
                ),

              // If there's video recorded show small tile (and optional thumbnail)
              if (_videoFilePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      const Icon(Icons.videocam, color: Colors.pinkAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Video Recorded • ${_shortFileName(_videoFilePath)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        onPressed: _deleteVideo,
                        icon: const Icon(Icons.delete, color: Colors.white38),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Bottom control row: either buttons or nothing (or both tiles shown above)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    if (_audioFilePath == null) _buildAudioControl(),
                    if (_videoFilePath == null) _buildVideoControl(),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width *
                          _buttonWidthAnim.value,
                      child: ElevatedButton.icon(
                        onPressed: _onNextPressed,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text(
                          'Next',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B4BFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioControl() {
    return Row(
      children: [
        // Record / Stop button
        GestureDetector(
          onTap: () async {
            if (_isRecordingAudio) {
              // stop and keep
              await _stopRecordingAudio(keep: true);
            } else {
              // start recording
              await _startRecordingAudio();
            }
          },
          onLongPress: () async {
            // user can long press to cancel instead (optional)
            if (_isRecordingAudio) {
              await _cancelRecordingAudio(); // discard
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isRecordingAudio
                  ? Colors.redAccent
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isRecordingAudio ? Icons.stop : Icons.mic,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Waveform or hint
        if (_isRecordingAudio)
          Row(
            children: [
              const SizedBox(width: 6),
              _buildWaveform(_dbLevel),
              const SizedBox(width: 8),
              // Cancel button while recording
              GestureDetector(
                onTap: () async {
                  await _cancelRecordingAudio();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ],
          )
        else
          const Text(
            'Record an audio answer',
            style: TextStyle(color: Colors.white54),
          ),
      ],
    );
  }

  Widget _buildVideoControl() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            if (_isRecordingVideo) {
              await _stopRecordingVideo(keep: true);
            } else {
              await _startRecordingVideo();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isRecordingVideo
                  ? Colors.redAccent
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isRecordingVideo ? Icons.stop_circle : Icons.videocam,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_isRecordingVideo)
          GestureDetector(
            onTap: _cancelRecordingVideo,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          )
        else
          const Text(
            'Record a short video',
            style: TextStyle(color: Colors.white54),
          ),
      ],
    );
  }
}
