import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraDialog extends StatefulWidget {
  const CameraDialog({super.key});

  @override
  State<CameraDialog> createState() => _CameraDialogState();
}

class _CameraDialogState extends State<CameraDialog> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _error;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _error = null;
      });
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'No se encontraron cámaras disponibles.';
            _isInitializing = false;
          });
        }
        return;
      }

      // Buscar cámara frontal si es posible
      CameraDescription? selectedCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }
      selectedCamera ??= cameras.first;

      if (_controller != null) {
        await _controller!.dispose();
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        String msg = 'Error al inicializar cámara: $e';
        if (e.toString().contains('CameraAccessDenied')) {
          msg = 'Acceso denegado. Por favor, haz clic en el icono del candado (🔒) en la parte superior izquierda de tu navegador y permite el uso de la cámara para este sitio.';
        }
        setState(() {
          _error = msg;
          _isInitializing = false;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Capturar Foto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 300,
                width: double.infinity,
                color: Colors.black,
                child: _buildCameraPreview(),
              ),
            ),
            const SizedBox(height: 24),
            if (_isInitialized && _error == null)
              ElevatedButton.icon(
                onPressed: _takePicture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB1CB34),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('TOMAR FOTO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              )
            else if (_error != null)
              Column(
                children: [
                   ElevatedButton.icon(
                    onPressed: _initializeCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF344092),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('REINTENTAR CONEXIÓN', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            else if (_isInitializing)
              const Text('Iniciando cámara...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)));
    }
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return CameraPreview(_controller!);
  }

  Future<void> _takePicture() async {
    if (!_isInitialized || _controller!.value.isTakingPicture) return;

    try {
      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, photo);
      }
    } catch (e) {
      debugPrint('Error al tomar foto: $e');
    }
  }
}
