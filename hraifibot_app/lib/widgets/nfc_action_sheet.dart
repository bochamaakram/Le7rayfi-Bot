import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/nfc_service.dart';

enum NfcMode { read, write }

class NfcActionSheet extends StatefulWidget {
  final NfcMode initialMode;
  final Function(String artisanId) onReadSuccess;

  const NfcActionSheet({
    super.key,
    required this.initialMode,
    required this.onReadSuccess,
  });

  @override
  State<NfcActionSheet> createState() => _NfcActionSheetState();
}

class _NfcActionSheetState extends State<NfcActionSheet> with SingleTickerProviderStateMixin {
  late NfcMode _mode;
  String _selectedArtisan = 'ART-DEMO-01';
  String _statusMessage = '';
  bool _isScanning = false;
  bool _isSuccess = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startNfcProcess();
  }

  void _startNfcProcess() {
    final loc = AppLocalization();
    setState(() {
      _isScanning = true;
      _isSuccess = false;
      _statusMessage = _mode == NfcMode.read ? loc.tr('nfc.scanning') : loc.tr('nfc.writing');
    });

    if (_mode == NfcMode.read) {
      NfcService().startReadSession(
        onRead: (artisanId, raw) {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _isSuccess = true;
            _statusMessage = loc.tr('nfc.readOk', {'id': artisanId});
          });
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) {
              Navigator.of(context).pop();
              widget.onReadSuccess(artisanId);
            }
          });
        },
        onError: (errKey) {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _statusMessage = loc.tr(errKey);
          });
        },
      );
    } else {
      NfcService().startWriteSession(
        artisanId: _selectedArtisan,
        onWritten: () {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _isSuccess = true;
            _statusMessage = loc.tr('nfc.writeOk');
          });
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (mounted) Navigator.of(context).pop();
          });
        },
        onError: (errKey) {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _statusMessage = loc.tr(errKey);
          });
        },
      );
    }
  }

  @override
  void dispose() {
    NfcService().stopSession();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization();
    return Directionality(
      textDirection: loc.direction,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Mode Selector tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(loc.tr('btn.nfcRead')),
                  selected: _mode == NfcMode.read,
                  selectedColor: const Color(0xFF06B6D4),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _mode = NfcMode.read);
                      _startNfcProcess();
                    }
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text(loc.tr('btn.nfcWrite')),
                  selected: _mode == NfcMode.write,
                  selectedColor: const Color(0xFFD97706),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _mode = NfcMode.write);
                      _startNfcProcess();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Animated Radar Pulse
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isScanning)
                      Container(
                        width: 90 * _pulseAnimation.value,
                        height: 90 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_mode == NfcMode.read ? const Color(0xFF06B6D4) : const Color(0xFFD97706))
                              .withOpacity((1.3 - _pulseAnimation.value).clamp(0.0, 0.4)),
                        ),
                      ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSuccess
                            ? const Color(0xFF10B981)
                            : (_mode == NfcMode.read ? const Color(0xFF0284C7) : const Color(0xFFD97706)),
                        boxShadow: [
                          BoxShadow(
                            color: (_isSuccess ? const Color(0xFF10B981) : const Color(0xFF06B6D4)).withOpacity(0.5),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSuccess ? Icons.check_rounded : Icons.nfc_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Status message
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isSuccess ? const Color(0xFF10B981) : Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            // Demo notice
            Text(
              loc.tr('demo.banner'),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Action / Cancel button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      NfcService().stopSession();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(loc.tr('voice.cancel')),
                  ),
                ),
                if (!_isScanning && !_isSuccess) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startNfcProcess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(loc.tr('btn.send')),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
