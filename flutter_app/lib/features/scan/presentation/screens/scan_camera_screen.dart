import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../farm/providers/farm_provider.dart';
import '../providers/scan_provider.dart';

class ScanCameraScreen extends ConsumerStatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  ConsumerState<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends ConsumerState<ScanCameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _hasError = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _hasError = true);
        return;
      }

      // Use the first rear camera
      final rearCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied' || e.code == 'cameraPermission') {
        if (mounted) setState(() => _permissionDenied = true);
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      // Fallback: if camera is not initialized, use ImagePicker camera
      _fallbackCapture();
      return;
    }

    try {
      final file = await _controller!.takePicture();
      _onPhotoCaptured(file);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.somethingWentWrong}: $e')),
        );
      }
    }
  }

  Future<void> _fallbackCapture() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      _onPhotoCaptured(file);
    }
  }

  Future<void> _uploadFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      _onPhotoCaptured(file);
    }
  }

  void _onPhotoCaptured(XFile file) {
    ref.read(scanProvider.notifier).setImage(file);
    context.push(AppRoutes.scanPreview);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedFarm = ref.watch(selectedFarmProvider);
    final crop = selectedFarm?.crop;
    final cropName = crop != null
        ? '${crop[0].toUpperCase()}${crop.substring(1)}'
        : l10n.scan;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          l10n.scanningFor(cropName),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview or Fallback Placeholder
          if (_permissionDenied)
            _buildPermissionDenied(l10n)
          else if (_isCameraInitialized && _controller != null)
            Center(child: CameraPreview(_controller!))
          else
            _buildCameraFallback(l10n),

          // Crop Overlay Guide (Grid / Box in middle)
          if (!_permissionDenied) _buildCropOverlayGuide(),

          // Bottom Bar containing Take Photo / Upload from Gallery
          if (!_permissionDenied)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.fitLeafInGuide,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                              onPressed: _uploadFromGallery,
                            ),
                            Text(l10n.uploadFromGallery, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),

                        // Take Photo Shutter
                        GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            height: 72,
                            width: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Spacer to balance layout
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Error state: Camera permission denied — per App Flow doc
  Widget _buildPermissionDenied(AppLocalizations l10n) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 64, color: AppTheme.errorRed),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                l10n.cameraPermissionRequired,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                l10n.allowCameraAccess,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              ElevatedButton.icon(
                onPressed: _uploadFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.uploadFromGallery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFallback(AppLocalizations l10n) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              _hasError ? l10n.cameraUnavailable : l10n.initializingCamera,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_hasError) ...[
              const SizedBox(height: AppTheme.spacingMd),
              ElevatedButton(
                onPressed: _fallbackCapture,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: Text(l10n.openSystemCamera),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCropOverlayGuide() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.maxWidth * 0.7; // Size of crop square
        return Stack(
          children: [
            // Darkened outer boundaries
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.black, // Background color for opacity filter
                  ),
                  Center(
                    child: Container(
                      height: size,
                      width: size,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Green overlay border
            Center(
              child: Container(
                height: size,
                width: size,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryGreen, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
