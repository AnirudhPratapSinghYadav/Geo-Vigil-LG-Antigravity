import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lg_final_app/screens/connection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  final FlutterTts flutterTts = FlutterTts();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Immersive mode hides the status bar for a professional look
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initSequence();
  }

  Future<void> _initSequence() async {
    // 1. Initialize Video First (The visual base)
    _controller = VideoPlayerController.asset('assets/intro.mp4');
    
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.setLooping(true); // Loops until voice completes
      }

      // 2. STAGGERED START: Yield to the main thread so video renders
      await Future.delayed(const Duration(milliseconds: 800));

      // 3. Setup and Trigger AI Voice
      await flutterTts.setLanguage("en-US");
      await flutterTts.setVolume(1.0);
      await flutterTts.setSpeechRate(0.5);
      
      // The voice command for GSoC judges
      await flutterTts.speak("Welcome to Liquid Galaxy’s Earthquake Live Dashboard. Systems online. Synchronizing tectonic data.");
      
      // 4. THE LOCK: Wait for 100% voice completion before SSH logic starts
      await flutterTts.awaitSpeakCompletion(true); 

      // 5. Navigate to Connection Page (No 'const' used here to avoid build errors)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ConnectionPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      debugPrint("Media Error: $e");
      // Fallback: If media fails, go to connection so you can still record the rig
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ConnectionPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    // Restore System UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Crucial to prevent white flashes
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
            
          // Optional: Overlay text to show during splash
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "GSoC 2026 SUBMISSION",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 4,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}