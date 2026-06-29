import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../util/display_date.dart';
import '../../vehicle/vehicle_stored_image.dart';

class VehicleDetailGalleryView extends StatefulWidget {
  const VehicleDetailGalleryView({
    super.key,
    required this.vehicleId,
    required this.dateFormat,
  });

  final String vehicleId;
  final String dateFormat;

  @override
  State<VehicleDetailGalleryView> createState() =>
      _VehicleDetailGalleryViewState();
}

class _VehicleDetailGalleryViewState extends State<VehicleDetailGalleryView> {
  late Future<List<_GalleryWithPhotos>> _future;
  bool _showEarlierGalleries = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant VehicleDetailGalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleId != widget.vehicleId ||
        oldWidget.dateFormat != widget.dateFormat) {
      _future = _load();
    }
  }

  Future<List<_GalleryWithPhotos>> _load() async {
    final repo = VehiclesRepository(AppDatabase.processScope);
    final galleries = await repo.listPhotoGalleries(widget.vehicleId);
    final result = <_GalleryWithPhotos>[];
    for (final gallery in galleries) {
      final photos = await repo.listGalleryPhotos(gallery.id);
      if (photos.isEmpty) continue;
      final title = formatPreferenceDate(gallery.createdAt, widget.dateFormat);
      result.add(_GalleryWithPhotos(title: title, photos: photos));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<_GalleryWithPhotos>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final galleries = snap.data!;
        final latest = galleries.first;
        final earlier = galleries.length > 1 ? galleries.sublist(1) : const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GallerySection(gallery: latest),
            if (earlier.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(
                    () => _showEarlierGalleries = !_showEarlierGalleries,
                  ),
                  child: Text(l10n.vehicleDetailEarlierPhotos),
                ),
              ),
              if (_showEarlierGalleries)
                for (final gallery in earlier) ...[
                  const SizedBox(height: 8),
                  _GallerySection(gallery: gallery),
                ],
            ],
          ],
        );
      },
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.gallery});

  final _GalleryWithPhotos gallery;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gallery.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              gallery.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        _GalleryPhotoCarousel(photos: gallery.photos),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GalleryPhotoCarousel extends StatefulWidget {
  const _GalleryPhotoCarousel({required this.photos});

  final List<VehicleGalleryPhoto> photos;

  @override
  State<_GalleryPhotoCarousel> createState() => _GalleryPhotoCarouselState();
}

class _GalleryPhotoCarouselState extends State<_GalleryPhotoCarousel> {
  static const double _height = 200;
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _GalleryFullscreenView(
          photos: widget.photos,
          initialIndex: _index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final current = photos[_index];
    final description = current.description.trim();
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final descriptionLineHeight =
        (textStyle?.fontSize ?? 14.0) * (textStyle?.height ?? 1.43);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onDoubleTap: _openFullscreen,
          child: SizedBox(
            height: _height,
            child: photos.length == 1
                ? VehicleStoredImage(
                    path: photos.first.relativeFilePath,
                    height: _height,
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: VehicleStoredImage(
                          path: photos[index].relativeFilePath,
                          height: _height,
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(photos.length, (i) {
              final selected = i == _index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 8 : 6,
                  height: selected ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: descriptionLineHeight,
            child: Center(
              child: Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GalleryFullscreenView extends StatefulWidget {
  const _GalleryFullscreenView({
    required this.photos,
    required this.initialIndex,
  });

  final List<VehicleGalleryPhoto> photos;
  final int initialIndex;

  @override
  State<_GalleryFullscreenView> createState() => _GalleryFullscreenViewState();
}

class _GalleryFullscreenViewState extends State<_GalleryFullscreenView> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final description = photos[_index].description.trim();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          photos.length == 1
              ? InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: VehicleStoredImage(
                    path: photos.first.relativeFilePath,
                    expand: true,
                    fit: BoxFit.cover,
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: VehicleStoredImage(
                        path: photos[index].relativeFilePath,
                        expand: true,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (description.isNotEmpty)
                        Expanded(
                          child: Text(
                            description,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.black,
                                    ),
                          ),
                        )
                      else
                        const Spacer(),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryWithPhotos {
  const _GalleryWithPhotos({required this.title, required this.photos});

  final String title;
  final List<VehicleGalleryPhoto> photos;
}

String vehicleModelColorSummary(AppLocalizations l10n, Vehicle vehicle) {
  final model = vehicle.model.trim();
  final color = vehicle.color.trim();
  if (model.isEmpty && color.isEmpty) return '';
  if (model.isEmpty) return color;
  if (color.isEmpty) return model;
  return '$model $color';
}
