import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import '../../app/constants.dart';

class ImageEditorScreen extends StatefulWidget {
  final File imageFile;

  const ImageEditorScreen({super.key, required this.imageFile});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late File _currentFile;
  bool _isProcessing = false;
  double _brightness = 0.0;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _processImage({
    bool rotate = false,
    int? resizeWidth,
    int? resizeHeight,
    bool cropSquare = false,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _currentFile.readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded != null) {
        if (rotate) {
          decoded = img.copyRotate(decoded, angle: 90);
        }
        if (cropSquare) {
          final size = decoded.width < decoded.height ? decoded.width : decoded.height;
          final x = (decoded.width - size) ~/ 2;
          final y = (decoded.height - size) ~/ 2;
          decoded = img.copyCrop(decoded, x: x, y: y, width: size, height: size);
        }
        if (resizeWidth != null && resizeHeight != null) {
          decoded = img.copyResize(decoded, width: resizeWidth, height: resizeHeight);
        }
        if (_brightness != 0.0) {
          decoded = img.adjustColor(decoded, brightness: 1.0 + _brightness);
        }

        final editedBytes = img.encodeJpg(decoded);
        final tempDir = Directory.systemTemp;
        final editedFile = File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await editedFile.writeAsBytes(editedBytes);

        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        setState(() {
          _currentFile = editedFile;
          _transformationController.value = Matrix4.identity();
        });
      }
    } catch (e) {
      debugPrint('Image processing error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Crop & Edit Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.orange, size: 28),
            onPressed: () => context.pop(_currentFile),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Movable & Zoomable Image underneath
                _isProcessing
                    ? const CircularProgressIndicator(color: AppColors.orange)
                    : InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Image.file(
                            _currentFile,
                            key: ValueKey(_currentFile.path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                // Static Crop Guide Frame on top (does not move)
                IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.orange, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 200,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pinch to zoom • Drag image beneath crop frame',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _toolButton(Icons.rotate_right_rounded, 'Rotate 90°', () => _processImage(rotate: true)),
                    _toolButton(Icons.crop_square_rounded, 'Crop Square', () => _processImage(cropSquare: true)),
                    _toolButton(Icons.aspect_ratio_rounded, 'Resize 800px', () => _processImage(resizeWidth: 800, resizeHeight: 800)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.dark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.pop(_currentFile),
                    child: const Text('Save & Apply Crop', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
