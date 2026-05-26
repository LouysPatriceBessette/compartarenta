import 'package:flutter/material.dart';

class FullscreenImageViewerScreen extends StatelessWidget {
  const FullscreenImageViewerScreen({
    super.key,
    required this.image,
    this.title,
  });

  final ImageProvider<Object> image;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: title == null
            ? null
            : Text(
                title!,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image(
                image: image,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 56,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(backLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
