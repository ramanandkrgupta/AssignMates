import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

enum MediaType { image, video, pdf }

class MediaViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String title;

  const MediaViewerScreen({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.title = 'View Media',
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late int _currentIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initMedia();
  }

  void _initMedia() {
    final url = widget.urls[_currentIndex];
    if (_isType(url, MediaType.video)) {
      _initVideo(url);
    } else {
      _disposeVideo();
    }
  }

  bool _isType(String url, MediaType type) {
    final uri = url.toLowerCase().split('?').first;
    switch (type) {
      case MediaType.image:
        return uri.contains('/images/') || uri.endsWith('.jpg') || uri.endsWith('.jpeg') || uri.endsWith('.png') || uri.endsWith('.webp') || uri.endsWith('.gif');
      case MediaType.video:
        return uri.contains('/videos/') || uri.endsWith('.mp4') || uri.endsWith('.mov') || uri.endsWith('.avi') || uri.endsWith('.mkv');
      case MediaType.pdf:
        return uri.contains('/pdfs/') || uri.endsWith('.pdf');
    }
  }

  MediaType _getMediaType(String url) {
    if (_isType(url, MediaType.video)) return MediaType.video;
    if (_isType(url, MediaType.pdf)) return MediaType.pdf;
    return MediaType.image;
  }

  Future<void> _initVideo(String url) async {
    _disposeVideo();
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFFFAF00),
        handleColor: const Color(0xFFFFAF00),
      ),
    );
    if (mounted) setState(() {});
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Future<void> _downloadCurrentFile() async {
    final url = widget.urls[_currentIndex];
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started...'), duration: Duration(seconds: 2)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start download'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFFFFAF00)),
            onPressed: _downloadCurrentFile,
            tooltip: 'Download Currently Viewed File',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildActiveMedia(),
          if (widget.urls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveMedia() {
    final url = widget.urls[_currentIndex];
    final type = _getMediaType(url);

    switch (type) {
      case MediaType.image:
        return PhotoViewGallery.builder(
          itemCount: widget.urls.length,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.urls[index]),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              errorBuilder: (context, error, stackTrace) => _buildErrorState('Failed to load image'),
            );
          },
          loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00))),
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: PageController(initialPage: widget.initialIndex),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              _initMedia();
            });
          },
        );
      case MediaType.video:
        if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
          return Center(child: Chewie(controller: _chewieController!));
        } else {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));
        }
      case MediaType.pdf:
        return Stack(
          children: [
            SfPdfViewer.network(
              url,
              onDocumentLoaded: (details) {
                if (mounted) setState(() => _isLoadingPdf = false);
              },
              onDocumentLoadFailed: (details) {
                if (mounted) {
                  setState(() {
                    _isLoadingPdf = false;
                    _pdfError = details.description;
                  });
                }
              },
            ),
            if (_isLoadingPdf)
              const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00))),
            if (_pdfError != null)
              _buildErrorState('Failed to load PDF: $_pdfError'),
          ],
        );
    }
  }

  bool _isLoadingPdf = true;
  String? _pdfError;

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.outfit(color: Colors.white70)),
        ],
      ),
    );
  }
}
