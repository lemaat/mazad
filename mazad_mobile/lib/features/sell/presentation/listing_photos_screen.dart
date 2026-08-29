import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/sell_repository.dart';

class ListingPhotosScreen extends StatefulWidget {
  const ListingPhotosScreen({
    super.key,
    required this.listingId,
    required this.repository,
  });
  final String listingId;
  final SellRepository repository;

  @override
  State<ListingPhotosScreen> createState() => _ListingPhotosScreenState();
}

class _ListingPhotosScreenState extends State<ListingPhotosScreen> {
  final _picker = ImagePicker();
  final List<File> _selected = [];
  bool _uploading = false;
  int _uploadedCount = 0;
  String? _error;
  bool _done = false;

  static const _maxPhotos = 5;

  Future<void> _pickPhoto() async {
    if (_selected.length >= _maxPhotos) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.maxPhotosReached)),
        );
      }
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _selected.add(File(picked.path)));
  }

  Future<void> _upload() async {
    if (_selected.isEmpty) return;
    setState(() {
      _uploading = true;
      _uploadedCount = 0;
      _error = null;
    });
    try {
      for (final file in List.of(_selected)) {
        await widget.repository.uploadListingImage(widget.listingId, file);
        if (!mounted) return;
        setState(() => _uploadedCount++);
      }
      if (mounted) setState(() => _done = true);
    } on SellException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listingPhotosTitle, style: AppTypography.body),
        automaticallyImplyLeading: !_uploading,
        leading: _uploading ? const SizedBox.shrink() : null,
      ),
      body: _done ? _buildDone(l10n) : _buildPicker(l10n),
    );
  }

  Widget _buildDone(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.surfaceWhite, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.photoUploadDone,
              style: AppTypography.body.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.done),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: _selected.isEmpty ? _buildEmpty(l10n, cs) : _buildGrid(cs),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: AppTypography.caption.copyWith(color: AppColors.error)),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_uploading) ...[
                  Text(
                    l10n.uploadingPhotoProgress(_uploadedCount + 1, _selected.length),
                    style: AppTypography.caption.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _selected.isEmpty ? 0 : _uploadedCount / _selected.length,
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  if (_selected.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _upload,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(l10n.uploadPhotos),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_selected.length < _maxPhotos)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(l10n.addPhotoButton),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations l10n, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.listingPhotosSubtitle,
              style: AppTypography.body.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(ColorScheme cs) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selected.length,
      itemBuilder: (_, i) => _PhotoTile(
        file: _selected[i],
        isUploaded: i < _uploadedCount,
        isUploading: _uploading,
        onRemove: _uploading ? null : () => setState(() => _selected.removeAt(i)),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.file,
    required this.isUploaded,
    required this.isUploading,
    required this.onRemove,
  });
  final File file;
  final bool isUploaded;
  final bool isUploading;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        if (isUploaded)
          Container(
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 32),
          )
        else if (!isUploading && onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
