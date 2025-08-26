import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:video_player/video_player.dart';
import 'package:nice_rice/pages/landingpage/landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _initTried = false;
  bool _initSucceeded = false;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();
    _warmUpThenInit();
  }

  Future<void> _warmUpThenInit() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVideo();
    });

    // Hard timeout: skip to landing if not ready fast enough
    _skipTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!_initSucceeded) _goToLanding();
    });
  }

  Future<void> _initVideo() async {
    if (_initTried) return;
    _initTried = true;

    try {
      // Ensure asset exists
      await rootBundle.load('assets/videos/splash.mp4');

      _controller = VideoPlayerController.asset(
        'assets/videos/splash.mp4',
        videoPlayerOptions: VideoPlayerOptions(),
      );

      await _controller.initialize();
      if (!mounted) return;

      _controller.setLooping(false);
      await _controller.setVolume(0.0);
      await _controller.play();

      _controller.addListener(_onVideoTick);

      setState(() {
        _initSucceeded = true;
      });
    } catch (e) {
      debugPrint('Splash init failed: $e');
      if (mounted) _goToLanding();
    }
  }

  void _onVideoTick() {
    final v = _controller.value;
    if (v.isInitialized && !v.isPlaying && v.position >= v.duration) {
      _goToLanding();
    }
    if (v.hasError) {
      debugPrint('Video error: ${v.errorDescription}');
      _goToLanding();
    }
  }

  void _goToLanding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LandingPage(), // <-- import your LandingPage here
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800), // fade speed
      ),
    );
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    if (_initSucceeded) {
      _controller.removeListener(_onVideoTick);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _initSucceeded && _controller.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 👈 background
      body: Center(
        child: isReady
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.7, // 👈 reduce size
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : _InstantSplashPoster(onTapToSkip: _goToLanding),
      ),
    );
  }
}

class _InstantSplashPoster extends StatelessWidget {
  final VoidCallback onTapToSkip;
  const _InstantSplashPoster({required this.onTapToSkip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapToSkip,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7, // 👈 same reduced size
        child: AspectRatio(
          aspectRatio: 16 / 9, // match your video’s ratio
          child: Image.asset(
            'assets/images/splash_poster.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
