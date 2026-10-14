import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../app_image.dart';
import '../feedback.dart';

/// Picks an image file from disk (driver photo, team logo) and previews it.
class ImagePickField extends StatefulWidget {
  static const maxBytes = 5 * 1024 * 1024;

  final String label;
  final String? currentPath;
  final IconData fallback;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const ImagePickField({
    super.key,
    required this.label,
    this.currentPath,
    this.fallback = Icons.image_outlined,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<ImagePickField> createState() => _ImagePickFieldState();
}

class _ImagePickFieldState extends State<ImagePickField> {
  String? _path;

  Future<void> _pick() async {
    const types = XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp']);
    final file = await openFile(acceptedTypeGroups: [types]);
    if (file == null || !mounted) return;
    if (await File(file.path).length() > ImagePickField.maxBytes) {
      if (mounted) showError(context, ApiException('The image is too large. Select an image up to 5 MB.'));
      return;
    }
    setState(() => _path = file.path);
    widget.onChanged(file.path);
  }

  void _reset() {
    setState(() => _path = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    const size = 88.0;
    return InputDecorator(
      decoration: InputDecoration(labelText: widget.label, errorText: widget.errorText),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _path != null
                ? Image.file(File(_path!), width: size, height: size, fit: BoxFit.cover)
                : AppImage(path: widget.currentPath, size: size, fallback: widget.fallback),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _path != null ? File(_path!).uri.pathSegments.last : 'JPG, PNG or WEBP, up to 5 MB.',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.upload_file), label: const Text('Choose image')),
                    if (_path != null) TextButton(onPressed: _reset, child: const Text('Clear selection')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
