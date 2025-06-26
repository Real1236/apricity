import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import '../services/entry_service.dart';

class GratitudeSnapScreen extends StatefulWidget {
  const GratitudeSnapScreen({super.key, required this.primaryCamera});

  final CameraDescription primaryCamera;

  @override
  State<GratitudeSnapScreen> createState() => GratitudeSnapScreenState();
}

class GratitudeSnapScreenState extends State<GratitudeSnapScreen> {
  CameraController? _controller;
  Future<void>? _initCameraFuture;
  XFile? _capturedImage;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> startCamera() async {
    if (_disposed || _controller != null) return;
    final controller = CameraController(
      widget.primaryCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller = controller;
    _initCameraFuture = controller.initialize();
    if (mounted) setState(() {});
  }

  Future<void> stopCamera() async {
    if (_disposed || _controller != null) return;
    if (_controller == null) return;
    await _controller!.dispose();
    _controller = null;
    _initCameraFuture = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    stopCamera();
    _disposed = true;
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      if (_controller == null) return;
      await _initCameraFuture!;
      final XFile image = await _controller!.takePicture();
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'gratitude_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedImagePath = '${appDir.path}/$fileName';
      await image.saveTo(savedImagePath);
      setState(() => _capturedImage = XFile(savedImagePath));
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _submitEntry() async {
    if (_capturedImage == null || _captionController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isUploading = true);

    try {
      await EntryService().createEntry(
        imageFile: File(_capturedImage!.path),
        caption: _captionController.text,
      );
    } catch (e) {
      debugPrint('Failed to create entry: $e');
    }

    if (mounted) {
      setState(() {
        _capturedImage = null;
        _captionController.clear();
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gratitude saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initCameraFuture == null
          ? const Center(child: Text('Camera stopped'))
          : FutureBuilder(
              future: _initCameraFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Column(
                    children: [
                      Expanded(
                        child: _capturedImage == null
                            ? CameraPreview(_controller!)
                            : Image.file(
                                File(_capturedImage!.path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: _captionController,
                          decoration: const InputDecoration(
                            labelText: 'What are you grateful for?',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            heroTag: 'snap',
                            onPressed: _takePicture,
                            child: const Icon(Icons.photo_camera),
                          ),
                          if (_capturedImage != null)
                            FilledButton.icon(
                              onPressed: _isUploading ? null : _submitEntry,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Save'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
    );
  }
}
