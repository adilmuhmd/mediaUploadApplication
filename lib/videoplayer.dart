import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';

class videoPlayer extends StatefulWidget {
  final String videoUrl;
  videoPlayer({required this.videoUrl});

  @override
  _videoPlayerState createState() => _videoPlayerState();
}

class _videoPlayerState extends State<videoPlayer> {
  late FlickManager flickManager;
  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
        videoPlayerController:
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl),
    ));
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Video Player",
        style: TextStyle(
            color: Colors.white
        ),
        ),
        centerTitle: true,
      ),
      body: Container(
        child: FlickVideoPlayer(
            flickManager: flickManager
        ),
      ),
    );
  }
}