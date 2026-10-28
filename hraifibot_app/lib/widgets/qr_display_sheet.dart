import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/localization_service.dart';

class QrDisplaySheet extends StatefulWidget {
  const QrDisplaySheet({super.key});

  @override
  State<QrDisplaySheet> createState() => _QrDisplaySheetState();
}

class _QrDisplaySheetState extends State<QrDisplaySheet> {
  int _selectedTab = 0; // 0 = Site, 1 = Demo Card

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization();
    final qrData = _selectedTab == 0
        ? 'https://le7rayfi.com'
        : 'https://bot.le7rayfi.com/?artisan=ART-DEMO-01';

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
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              loc.tr('qr.title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Toggle between Site and Demo Card
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(loc.isRtl ? 'موقع Le7rayfi' : 'Site Le7rayfi')),
                ButtonSegment(value: 1, label: Text(loc.isRtl ? 'بطاقة تجريبية' : 'Fiche Démo')),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (set) {
                setState(() => _selectedTab = set.first);
              },
            ),
            const SizedBox(height: 24),
            // QR Code Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.35),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              qrData,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF06B6D4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.tr('demo.banner'),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(loc.tr('voice.cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
