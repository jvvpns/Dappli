// lib/screens/ar_scanner_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'dart:ui';
import '../app_colors.dart';
import '../services/ingredient_detection_service.dart';
import '../services/ai_orchestrator_service.dart';
import '../models/detection_result.dart';
import 'generator_screen.dart';
import 'search_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ARScannerScreen extends StatefulWidget {
  const ARScannerScreen({super.key});

  @override
  State<ARScannerScreen> createState() => _ARScannerScreenState();
}

class _ARScannerScreenState extends State<ARScannerScreen> {
  static bool _hasSeenBriefing = false; // Persistent for session
  CameraController? _cameraController;
  late AIOrchestratorService _detectionService;

  List<DetectionResult> _detections = [];
  final Set<String> _selectedIngredients = {};

  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isDisposed = false;

  // For displaying the captured image with detections
  String? _lastCapturedImagePath;
  bool _showingResults = false;
  Size? _capturedImageSize; // 🆕 Store actual image dimensions

  @override
  void initState() {
    super.initState();
    _detectionService = AIOrchestratorService();
    _initializeDetectionService();
    _initializeCamera();
    
    // Auto-summon the Briefing on first session entry
    if (!_hasSeenBriefing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBriefing();
        _hasSeenBriefing = true;
      });
    }
  }

  Future<void> _initializeDetectionService() async {
    await _detectionService.initialize();

  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No camera found');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high, // Use high for better detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted || _isDisposed) return;

      if (!_cameraController!.value.isInitialized) {
        throw Exception('Camera failed to initialize');
      }

      setState(() => _isCameraReady = true);
    } catch (e, stackTrace) {
      if (mounted) {
        _showError('Failed to initialize camera: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.accent),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  Future<void> _captureAndDetect() async {
    if (!mounted ||
        _isDisposed ||
        _isProcessing ||
        !_detectionService.isInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // 1. Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      // 2. Immediate freeze-frame UI update
      final imageBytes = await File(imageFile.path).readAsBytes();
      final decodedImage = await decodeImageFromList(imageBytes);
      final actualWidth = decodedImage.width.toDouble();
      final actualHeight = decodedImage.height.toDouble();

      setState(() {
        _isProcessing = true;
        _showingResults = true; // Show the image immediately
        _lastCapturedImagePath = imageFile.path;
        _capturedImageSize = Size(actualWidth, actualHeight);
        _detections = []; // Clear old detections
      });

      // 3. Background detection
      final rawResults = await _detectionService.detectFromImagePath(imageFile.path);

      if (!mounted || _isDisposed) {
        await File(imageFile.path).delete();
        return;
      }

      if (rawResults.isEmpty) {
        setState(() {
          _isProcessing = false;
          _showingResults = false;
        });
        await File(imageFile.path).delete();
        _showError('No ingredients detected. Try again.');
        return;
      }

      // 4. Coordinates scaling
      final scaleX = actualWidth;
      final scaleY = actualHeight;

      final results = rawResults.map((r) {
        final box = List<double>.from(r['box']);
        final scaledBox = [
          box[0] * scaleX,
          box[1] * scaleY,
          box[2] * scaleX,
          box[3] * scaleY,
        ];

        return DetectionResult(
          label: r['label'],
          confidence: r['confidence'],
          boundingBox: Rect.fromLTRB(
            scaledBox[0],
            scaledBox[1],
            scaledBox[2],
            scaledBox[3],
          ),
          timestamp: DateTime.now(),
        );
      }).toList();

      results.sort((a, b) => b.confidence.compareTo(a.confidence));

      if (!mounted || _isDisposed) return;

      // 5. Finalize UI with detections
      setState(() {
        _detections = results;
        _isProcessing = false;
      });

    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isProcessing = false;
          _showingResults = false;
        });
        _showError('Detection failed. Try again.');
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _showingResults = false;
      _detections.clear();
      _capturedImageSize = null; // 🆕 Clear stored size
      if (_lastCapturedImagePath != null) {
        File(_lastCapturedImagePath!).delete().catchError((e) {
          print('⚠️ Could not delete temp file: $e');
        });
        _lastCapturedImagePath = null;
      }
    });
  }

  void _addDetectedIngredients() {
    final newIngredients = <String>[];

    for (var detection in _detections) {
      if (detection.isHighlyConfident && !_selectedIngredients.contains(detection.label)) {
        _selectedIngredients.add(detection.label);
        newIngredients.add(detection.label);
      }
    }

    if (newIngredients.isNotEmpty) {
      setState(() {});
      _showSuccess('Added ${newIngredients.length} ingredient(s)');
      _retakePhoto(); // Go back to camera view
    } else if (_detections.isNotEmpty) {
      _showError('No new high-confidence ingredients to add');
    }
  }

  void _navigateToGenerator() {
    if (_selectedIngredients.isEmpty) {
      _showError('Please scan at least one ingredient');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeneratorScreen(
          initialIngredients: _selectedIngredients.toList(),
        ),
      ),
    );
  }

  void _navigateToSearch() {
    if (_selectedIngredients.isEmpty) {
      _showError('Please scan at least one ingredient');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialIngredients: _selectedIngredients.toList(),
        ),
      ),
    );
  }

  void _clearAllIngredients() {
    setState(() {
      _selectedIngredients.clear();
      _detections.clear();
    });
    _showSuccess('Cleared all ingredients');
  }

  static const String _svgLens = '''<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="20" cy="20" r="18" stroke="#FBBC05" stroke-width="2"/>
<circle cx="20" cy="20" r="8" stroke="#FBBC05" stroke-width="1.5" stroke-dasharray="4 2"/>
<path d="M20 12V6M20 34V28M12 20H6M34 20H28" stroke="#FBBC05" stroke-width="2" stroke-linecap="round"/>
</svg>''';

  static const String _svgCheck = '''<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M8 20L16 28L32 12" stroke="#FBBC05" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="4" y="4" width="32" height="32" rx="4" stroke="#FBBC05" stroke-width="1.5" stroke-opacity="0.3"/>
</svg>''';

  static const String _svgMagic = '''<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M20 6L22.5 15.5L32 18L22.5 20.5L20 30L17.5 20.5L8 18L17.5 15.5L20 6Z" fill="#FBBC05"/>
<circle cx="8" cy="8" r="2" fill="#FBBC05" fill-opacity="0.6"/>
<circle cx="32" cy="30" r="3" fill="#FBBC05" fill-opacity="0.4"/>
</svg>''';

  void _showBriefing() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3C2F2F).withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFBBC05).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBC05), size: 48),
                const SizedBox(height: 16),
                const Text(
                  "CHEF'S BRIEFING",
                  style: TextStyle(
                    color: Color(0xFFFBBC05),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 24),
                _buildBriefingStep(
                  _svgLens,
                  "1. POINT & CAPTURE",
                  "Aim your lens at your harvest and capture the raw essentials for your dish.",
                ),
                const SizedBox(height: 20),
                _buildBriefingStep(
                  _svgCheck,
                  "2. VERIFY INGREDIENTS",
                  "Review the automated list and confirm the bounty for your collection.",
                ),
                const SizedBox(height: 20),
                _buildBriefingStep(
                  _svgMagic,
                  "3. AI RECIPE MAGIC",
                  "Let the AI Chef simmer your selected ingredients into professional recipes.",
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBC05),
                      foregroundColor: const Color(0xFF3C2F2F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "BEGIN SERVICE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBriefingStep(String svgString, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBC05).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.string(
            svgString,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Color(0xFFFBBC05), BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFBBC05),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.dispose();
    _cameraController = null;
    _detectionService.dispose();

    // Clean up temp file
    if (_lastCapturedImagePath != null) {
      File(_lastCapturedImagePath!).delete().catchError((e) {

      });
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          if (_showingResults && _lastCapturedImagePath != null)
            _buildResultsView()
          else if (_isCameraReady && _cameraController != null)
            _buildCameraView()
          else
            _buildLoadingView(),

          // Top Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ingredient Scanner',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _showingResults ? 'Review detections' : 'Tap camera to scan',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
                      onPressed: _showBriefing,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          const Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        // Processing indicator
        if (_isProcessing)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Analyzing ingredients...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsView() {
    return Stack(
      children: [
        // Display captured image
        Positioned.fill(
          child: Image.file(
            File(_lastCapturedImagePath!),
            fit: BoxFit.contain,
          ),
        ),
        
        // 🔹 Pulse Overlay during analysis
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulsingIcon(),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Text(
                            "ANALYZING...",
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 🔹 Draw bounding boxes with fade-in animation
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _isProcessing ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: CustomPaint(
              painter: DetectionPainter(
                _detections,
                _capturedImageSize!,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show detections if in results view
            if (_showingResults && _detections.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Detected Ingredients',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._detections.map((detection) {
                      final isAlreadyAdded = _selectedIngredients.contains(detection.label);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${detection.label}: ${(detection.confidence * 100).toStringAsFixed(2)}% confidence',
                                style: TextStyle(
                                  color: isAlreadyAdded ? Colors.white54 : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isAlreadyAdded)
                              const Icon(Icons.check, size: 18, color: Colors.white54),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _retakePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Retake'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _addDetectedIngredients,
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Add Ingredients'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.text,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Collected Ingredients
            if (_selectedIngredients.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.kitchen, color: AppColors.secondary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Collected (${_selectedIngredients.length})',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.clear_all, size: 18),
                          color: AppColors.accent,
                          onPressed: _clearAllIngredients,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _selectedIngredients.map((ingredient) {
                        return Chip(
                          label: Text(
                            ingredient,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: AppColors.secondary,
                          deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.text),
                          onDeleted: () => setState(() {
                            _selectedIngredients.remove(ingredient);
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToGenerator,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text("Generate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToSearch,
                      icon: const Icon(Icons.search),
                      label: const Text("Search"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Capture button (only show when not in results view)
            if (!_showingResults) ...[
              const SizedBox(height: 12),
              Center(
                child: FloatingActionButton.large(
                  onPressed: _isProcessing ? null : _captureAndDetect,
                  backgroundColor: AppColors.secondary,
                  elevation: 8,
                  child: Icon(
                    Icons.camera_alt,
                    size: 32,
                    color: _isProcessing ? Colors.grey : AppColors.text,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 🆕 Updated DetectionPainter with display scaling
class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size imageSize; // 🆕 Actual captured image dimensions

  DetectionPainter(this.detections, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    // 🆕 Calculate how the image fits in the display area (BoxFit.contain)
    final imageAspect = imageSize.width / imageSize.height;
    final displayAspect = size.width / size.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > displayAspect) {
      // Image is wider - fit to width
      scale = size.width / imageSize.width;
      final scaledHeight = imageSize.height * scale;
      offsetY = (size.height - scaledHeight) / 2;
    } else {
      // Image is taller - fit to height
      scale = size.height / imageSize.height;
      final scaledWidth = imageSize.width * scale;
      offsetX = (size.width - scaledWidth) / 2;
    }

    for (var detection in detections) {
      final box = detection.boundingBox;

      // 🆕 Scale box coordinates from image space to display space
      final displayBox = Rect.fromLTRB(
        box.left * scale + offsetX,
        box.top * scale + offsetY,
        box.right * scale + offsetX,
        box.bottom * scale + offsetY,
      );

      // 🎨 Premium Visuals: Rounded corners and Brand Yellow
      final boxPaint = Paint()
        ..color = AppColors.secondary.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(displayBox, const Radius.circular(12)),
        boxPaint,
      );

      // Label background (rounded)
      final textSpan = TextSpan(
        text: '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          displayBox.left,
          displayBox.top - textPainter.height - 10,
          textPainter.width + 16,
          textPainter.height + 6,
        ),
        const Radius.circular(8),
      );

      final bgPaint = Paint()..color = AppColors.secondary.withOpacity(0.9);
      canvas.drawRRect(labelBgRect, bgPaint);
      textPainter.paint(canvas, Offset(displayBox.left + 8, displayBox.top - textPainter.height - 8));
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) =>
      detections != oldDelegate.detections || imageSize != oldDelegate.imageSize;
}

class PulsingIcon extends StatefulWidget {
  const PulsingIcon({super.key});

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: AppColors.secondary,
        size: 64,
      ),
    );
  }
}