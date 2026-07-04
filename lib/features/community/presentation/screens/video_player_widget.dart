import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../utils/video_cache_manager.dart';
import 'package:ngo_app/core/utils/route_observer.dart';

class VideoThumbnailPlayer extends StatefulWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const VideoThumbnailPlayer({
    Key? key,
    required this.videoUrl,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<VideoThumbnailPlayer> createState() => _VideoThumbnailPlayerState();
}

class _VideoThumbnailPlayerState extends State<VideoThumbnailPlayer> with RouteAware {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isRouteActive = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPushNext() {
    _isRouteActive = false;
    _deactivatePlayer();
  }

  @override
  void didPopNext() {
    _isRouteActive = true;
    _initializePlayer();
  }

  void _deactivatePlayer() {
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  Future<void> _initializePlayer() async {
    if (!_isRouteActive) return;
    var url = widget.videoUrl;
    if (url.contains('ngo-app-d0961.appspot.com')) {
      debugPrint("VideoThumbnailPlayer: Mapping old storage bucket to active bucket.");
      url = url.replaceAll('ngo-app-d0961.appspot.com', 'connect-ngo-82057.firebasestorage.app');
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final cachedFile = await VideoCacheManager.getCachedFile(url);
      if (!mounted) return;

      if (cachedFile != null) {
        debugPrint("VideoThumbnailPlayer: Loading thumbnail from cache: ${cachedFile.path}");
        _controller = VideoPlayerController.file(cachedFile);
      } else {
        debugPrint("VideoThumbnailPlayer: Loading thumbnail from network: $url");
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
        VideoCacheManager.prefetchVideo(url);
      }

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (error) {
        debugPrint("VideoThumbnailPlayer: Initialization error: $error");
      }
    } else {
      debugPrint("VideoThumbnailPlayer: Invalid video URL structure: '$url'");
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade900,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}

class CommunityVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const CommunityVideoPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<CommunityVideoPlayer> createState() => _CommunityVideoPlayerState();
}

class _CommunityVideoPlayerState extends State<CommunityVideoPlayer> with RouteAware {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isRouteActive = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPushNext() {
    _isRouteActive = false;
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void didPopNext() {
    _isRouteActive = true;
  }

  Future<void> _initializePlayer() async {
    if (!_isRouteActive) return;
    var url = widget.videoUrl;
    if (url.contains('ngo-app-d0961.appspot.com')) {
      debugPrint("CommunityVideoPlayer: Mapping old storage bucket to active bucket.");
      url = url.replaceAll('ngo-app-d0961.appspot.com', 'connect-ngo-82057.firebasestorage.app');
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final cachedFile = await VideoCacheManager.getCachedFile(url);
      if (!mounted) return;

      if (cachedFile != null) {
        debugPrint("CommunityVideoPlayer: Loading video from cache: ${cachedFile.path}");
        _controller = VideoPlayerController.file(cachedFile);
      } else {
        debugPrint("CommunityVideoPlayer: Loading video from network: $url");
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
        VideoCacheManager.prefetchVideo(url);
      }

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (error) {
        debugPrint("CommunityVideoPlayer: Initialization error: $error");
      }
    } else {
      debugPrint("CommunityVideoPlayer: Invalid video URL structure: '$url'");
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),
              if (!_isPlaying)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF0099B8),
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
