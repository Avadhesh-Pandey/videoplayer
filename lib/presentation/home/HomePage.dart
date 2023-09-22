import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  Timer? t;
  Duration? lastPosition;

  @override
  void initState() {
    initialisePlayer();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      debugPrint("Connectivity() : ${result.name} , ${result.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.toString()),
        ),
      );
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        initialisePlayer();
      }
      // Got a new connectivity status!
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: videoPlayerController != null && videoPlayerController!.value.isInitialized
            ? Chewie(
                controller: chewieController!,
              )
            : const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  backgroundColor: Colors.grey,
                ),
              ),
      ),
    ));
  }

  @override
  void dispose() {
    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  /// in case network is dropped the system will try to check for connectivity every 3 seconds
  void checkInternet() {
    if (t == null || !t!.isActive) {
      chewieController?.pause();
      videoPlayerController?.pause();
      debugPrint("Connectivity() : checkInternet ");
      t = Timer.periodic(const Duration(seconds: 3), (Timer t) {
        Connectivity().checkConnectivity().then((value) {
          if (value == ConnectivityResult.mobile || value == ConnectivityResult.wifi) {
            if (chewieController == null || !chewieController!.isPlaying) {
              initialisePlayer();
              t.cancel();
            }
          }
        });
      });
    }
  }

  ///tracking the last position where the network got dropped
  void checkVideo() {
    if (videoPlayerController != null && videoPlayerController!.value.position > Duration.zero) {
      lastPosition = videoPlayerController!.value.position;
      debugPrint("duration : ${videoPlayerController!.value.position}");
    }
  }

  ///initializing the video player
  Future<void> initialisePlayer() async {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
        'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'));
    await videoPlayerController!.initialize();
    videoPlayerController!.addListener(checkVideo);
    chewieController = ChewieController(
        allowedScreenSleep: false,
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: true,
        errorBuilder: (context, error) {
          checkInternet();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Check your internet connection and try again",
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  error,
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              ],
            )),
          );
        });
    debugPrint("Connectivity() : $lastPosition ");
    if (lastPosition != null) {
      videoPlayerController?.seekTo(lastPosition!);
      chewieController?.seekTo(lastPosition!);
    }
    setState(() {});
  }
}
