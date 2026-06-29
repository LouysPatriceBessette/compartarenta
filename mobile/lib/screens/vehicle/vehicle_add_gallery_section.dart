import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../vehicle/vehicle_gallery_storage.dart';
import '../../widgets/app_text_field.dart';

class VehicleAddGallerySection extends StatefulWidget {
  const VehicleAddGallerySection({
    super.key,
    required this.galleries,
    required this.onChanged,
    this.allowAddAnotherGallery = false,
    this.showSectionHeader = true,
    this.startGalleryButtonLabel,
    this.newGalleryTitle,
  });

  final List<VehicleGalleryDraft> galleries;
  final VoidCallback onChanged;
  final bool allowAddAnotherGallery;
  final bool showSectionHeader;
  final String? startGalleryButtonLabel;
  final String? Function()? newGalleryTitle;

  @override
  State<VehicleAddGallerySection> createState() =>
      _VehicleAddGallerySectionState();
}

class _VehicleAddGallerySectionState extends State<VehicleAddGallerySection> {
  final _descriptionControllers =
      <VehicleGalleryPhotoDraft, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(VehicleGalleryPhotoDraft photo) {
    return _descriptionControllers.putIfAbsent(
      photo,
      () => TextEditingController(text: photo.description),
    );
  }

  void _notify() => widget.onChanged();

  Future<void> _addPhoto(int galleryIndex) async {
    final path = await pickVehicleGalleryPhotoSource(context);
    if (path == null || !mounted) return;
    setState(() {
      widget.galleries[galleryIndex].photos.add(
            VehicleGalleryPhotoDraft(sourcePath: path),
          );
    });
    _notify();
  }

  void _removePhoto(int galleryIndex, int photoIndex) {
    final photo = widget.galleries[galleryIndex].photos[photoIndex];
    _descriptionControllers.remove(photo)?.dispose();
    setState(() {
      widget.galleries[galleryIndex].photos.removeAt(photoIndex);
    });
    _notify();
  }

  void _addGallery() {
    final title = widget.newGalleryTitle?.call();
    setState(() {
      widget.galleries.add(VehicleGalleryDraft(displayTitle: title));
    });
    _notify();
  }

  String _galleryCardTitle(AppLocalizations l10n, VehicleGalleryDraft gallery, int galleryIndex) {
    final custom = gallery.displayTitle?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return l10n.vehicleAddGalleryTitle(galleryIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final startLabel =
        widget.startGalleryButtonLabel ?? l10n.vehicleAddGalleryStart;

    if (widget.galleries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showSectionHeader) ...[
            Text(
              l10n.vehicleAddPhotosSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.vehicleAddPhotosOptionalHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _addGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(startLabel),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSectionHeader) ...[
          Text(
            l10n.vehicleAddPhotosSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.vehicleAddPhotosOptionalHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        ...List.generate(widget.galleries.length, (galleryIndex) {
          final gallery = widget.galleries[galleryIndex];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _galleryCardTitle(l10n, gallery, galleryIndex),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (gallery.photos.isEmpty)
                    Text(l10n.vehicleAddGalleryEmpty)
                  else
                    ...List.generate(gallery.photos.length, (photoIndex) {
                      final photo = gallery.photos[photoIndex];
                      final controller = _controllerFor(photo);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _PhotoPreview(path: photo.sourcePath),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: l10n.vehicleAddGalleryDescription,
                              ),
                              onChanged: (value) {
                                photo.description = value;
                                _notify();
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _removePhoto(galleryIndex, photoIndex),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l10n.commonDelete),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addPhoto(galleryIndex),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(l10n.vehicleAddGalleryAddPhoto),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (widget.allowAddAnotherGallery)
          OutlinedButton.icon(
            onPressed: _addGallery,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: Text(l10n.vehicleAddGalleryAddGallery),
          ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        height: 160,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, size: 48),
      );
    }
    return Image.file(
      File(path),
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
