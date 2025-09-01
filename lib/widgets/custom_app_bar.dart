import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/dynamic_links_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Map<String, dynamic>? vehicleDetails;
  final bool showBackButton;
  final bool showShareButton;
  final bool showFavoriteButton;
  final Function? onBackPressed;
  final Color backgroundColor;
  final Color iconColor;
  final Widget? leadingWidget; // Add this field

  const CustomAppBar({
    super.key,
    required this.title,
    this.vehicleDetails,
    this.showBackButton = true,
    this.showShareButton = false,
    this.showFavoriteButton = false,
    this.onBackPressed,
    this.backgroundColor = Colors.transparent,
    this.iconColor = Colors.white,
    this.leadingWidget, // Add this parameter
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showFavoriteButton && widget.vehicleDetails != null) {
      _checkFavoriteStatus();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.vehicleDetails == null || widget.vehicleDetails!['id'] == null)
      return;

    setState(() => _loading = true);
    try {
      final bool isFav =
          await _favoritesService.isFavorite(widget.vehicleDetails!['id']);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.vehicleDetails == null) return;

    try {
      setState(() => _loading = true);
      final bool newStatus =
          await _favoritesService.toggleFavorite(widget.vehicleDetails!);
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareVehicle() async {
    if (widget.vehicleDetails == null) return;
    await DynamicLinksService.shareVehicle(widget.vehicleDetails!, context);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: widget.backgroundColor,
      elevation: 0,
      leading: widget.leadingWidget ??
          (widget.showBackButton
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: widget.iconColor),
                  ),
                  onPressed: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                )
              : null),
      actions: [
        // Share button
        if (widget.showShareButton)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share, color: widget.iconColor),
            ),
            onPressed: _shareVehicle,
          ),

        // Favorite button
        if (widget.showFavoriteButton)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.iconColor,
                      ),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : widget.iconColor,
                    ),
            ),
            onPressed: _toggleFavorite,
          ),
      ],
    );
  }
}
