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
    return FutureBuilder<List<_GalleryWithPhotos>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final galleries = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final gallery in galleries) ...[
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
          ],
        );
      },
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
        SizedBox(
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
