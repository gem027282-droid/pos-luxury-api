import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera Barcode Scanner Controller with strict 1800ms Debounce Latch
/// and Haptic Feedback to eliminate duplicate reads across video frames.
class BarcodeScannerHandler {
  final MobileScannerController scannerController;
  final Duration debounceDuration;
  final void Function(String barcode) onBarcodeDetected;

  bool _isLocked = false;
  String? _lastScannedCode;
  Timer? _lockTimer;

  BarcodeScannerHandler({
    required this.onBarcodeDetected,
    this.debounceDuration = const Duration(milliseconds: 1800),
    CameraFacing facing = CameraFacing.back,
  }) : scannerController = MobileScannerController(
          facing: facing,
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: false,
        );

  bool get isLocked => _isLocked;
  String? get lastScannedCode => _lastScannedCode;

  void handleBarcodeCapture(BarcodeCapture capture) {
    if (_isLocked) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    // Check if duplicate immediate frame
    if (_lastScannedCode == rawValue && _isLocked) return;

    // 1. Lock the scanner immediately
    _isLocked = true;
    _lastScannedCode = rawValue;

    // 2. Trigger Heavy Haptic Vibration
    HapticFeedback.heavyImpact();

    // 3. Dispatch scanned product to POS Cart
    onBarcodeDetected(rawValue);

    // 4. Set unlock timer with debounce latch (1800ms)
    _lockTimer?.cancel();
    _lockTimer = Timer(debounceDuration, () {
      _isLocked = false;
    });
  }

  void resetLock() {
    _lockTimer?.cancel();
    _isLocked = false;
    _lastScannedCode = null;
  }

  void dispose() {
    _lockTimer?.cancel();
    scannerController.dispose();
  }
}
