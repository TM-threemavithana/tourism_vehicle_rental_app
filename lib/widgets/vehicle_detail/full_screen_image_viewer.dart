import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _baseOffset = Offset.zero;
  BoxFit _currentFit =
      BoxFit.fitWidth; // Change to fitWidth for better vehicle image display

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen image viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _resetZoom();
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Single tap to show/hide UI
                  setState(() {
                    // Toggle UI visibility
                  });
                },
                onDoubleTap: () {
                  // Double tap to zoom in/out
                  setState(() {
                    if (_scale > 1.0) {
                      _resetZoom();
                    } else {
                      _scale = 2.0;
                    }
                  });
                },
                onScaleStart: (details) {
                  _baseOffset = _offset;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _scale = details.scale.clamp(1.0, 3.0);
                    _offset = _baseOffset + details.focalPointDelta;
                  });
                },
                onScaleEnd: (details) {
                  _baseOffset = _offset;
                },
                child: Center(
                  child: Transform.scale(
                    scale: _scale,
                    child: Transform.translate(
                      offset: _offset,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrls[index],
                          fit: _currentFit,
                          placeholder: (context, url) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.error,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top app bar with close button and image counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // Image counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Share button (placeholder)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  // Fit mode toggle button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_currentFit == BoxFit.fitWidth) {
                          _currentFit = BoxFit.contain;
                        } else if (_currentFit == BoxFit.contain) {
                          _currentFit = BoxFit.cover;
                        } else if (_currentFit == BoxFit.cover) {
                          _currentFit = BoxFit.fill;
                        } else {
                          _currentFit = BoxFit.fitWidth;
                        }
                        _resetZoom();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getFitModeIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom indicator dots
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.imageUrls.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(
                        _currentIndex == entry.key ? 0.9 : 0.4,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Zoom indicator
          if (_scale > 1.0)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 60,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_scale * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Fit mode indicator
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getFitModeText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetZoom() {
    _scale = 1.0;
    _offset = Offset.zero;
    _baseOffset = Offset.zero;
  }

  IconData _getFitModeIcon() {
    switch (_currentFit) {
      case BoxFit.fitWidth:
        return Icons.aspect_ratio;
      case BoxFit.contain:
        return Icons.zoom_in;
      case BoxFit.cover:
        return Icons.zoom_out_map;
      case BoxFit.fill:
        return Icons.zoom_in_map;
      default:
        return Icons.aspect_ratio;
    }
  }

  String _getFitModeText() {
    switch (_currentFit) {
      case BoxFit.fitWidth:
        return 'Fit Width';
      case BoxFit.contain:
        return 'Contain';
      case BoxFit.cover:
        return 'Cover';
      case BoxFit.fill:
        return 'Fill';
      default:
        return 'Fit Width';
    }
  }
}
