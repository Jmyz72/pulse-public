import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Full-screen image viewer with pinch-to-zoom and pan
///
/// Features:
/// - InteractiveViewer for zoom and pan
/// - Hero animation support
/// - Glassmorphic app bar
/// - Deep obsidian background
class ImageLightbox extends StatelessWidget {
  final String? imageUrl;
  final String? imageFilePath;
  final String? heroTag;

  const ImageLightbox({
    super.key,
    this.imageUrl,
    this.imageFilePath,
    this.heroTag,
  }) : assert(
         (imageUrl != null) != (imageFilePath != null),
         'Provide either imageUrl or imageFilePath',
       );

  /// Show the image lightbox as a full-screen dialog
  static void show(BuildContext context, String imageUrl, [String? heroTag]) {
    showNetwork(context, imageUrl, heroTag);
  }

  static void showNetwork(
    BuildContext context,
    String imageUrl, [
    String? heroTag,
  ]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageLightbox(imageUrl: imageUrl, heroTag: heroTag),
        fullscreenDialog: true,
      ),
    );
  }

  static void showFile(
    BuildContext context,
    String imageFilePath, [
    String? heroTag,
  ]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ImageLightbox(imageFilePath: imageFilePath, heroTag: heroTag),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildImage() {
    if (imageFilePath != null) {
      return Image.file(
        File(imageFilePath!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image,
          size: 64,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.broken_image,
        size: 64,
        color: AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Close',
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: heroTag != null
              ? Hero(tag: heroTag!, child: _buildImage())
              : _buildImage(),
        ),
      ),
    );
  }
}
