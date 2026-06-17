import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

/// Scan screen — camera capture or gallery upload for crop disease diagnosis.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  XFile? _selectedImage;
  bool _isAnalysing = false;

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _analyseCrop() async {
    if (_selectedImage == null) return;
    setState(() => _isAnalysing = true);

    try {
      final dio = Dio(BaseOptions(headers: {'Bypass-Tunnel-Reminder': 'true'}));
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: _selectedImage!.name,
        ),
        'farm_context': 'Tomato', // TODO: Fetch from selected farm
      });

      final response = await dio.post(
        '${AppConstants.baseUrl}/api/diagnose',
        data: formData,
      );

      if (mounted) {
        // Show the result
        final result = response.data;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Scan Result'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disease: ${result['disease']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Confidence: ${(result['confidence'] * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 8),
                Text('Recommendation: ${result['recommendation']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalysing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Your Crop')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            // Current farm context
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco, color: AppTheme.primaryGreen),
                  SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Scanning for: 🍅 Tomato', // TODO: Dynamic from selected farm
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Camera / Preview area
            Expanded(
              child: _selectedImage == null
                  ? _buildCameraPlaceholder()
                  : _buildPreview(),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Action buttons
            if (_selectedImage == null) ...[
              ElevatedButton.icon(
                onPressed: _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Upload from Gallery'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _isAnalysing ? null : _analyseCrop,
                child: _isAnalysing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Analysing your crop...'),
                        ],
                      )
                    : const Text('Use This Photo'),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              OutlinedButton(
                onPressed: () => setState(() => _selectedImage = null),
                child: const Text('Retake'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.dividerGray, width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: AppTheme.textHint),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'Point your camera at the affected leaf',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: kIsWeb
            ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
      ),
    );
  }
}
