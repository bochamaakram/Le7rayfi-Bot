import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

typedef NfcSuccessCallback = void Function(String artisanId, String rawData);
typedef NfcErrorCallback = void Function(String error);

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  bool _isSessionActive = false;
  bool get isSessionActive => _isSessionActive;

  Future<bool> checkAvailability() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      return availability == NfcAvailability.enabled;
    } catch (e) {
      return false;
    }
  }

  Future<void> startReadSession({
    required NfcSuccessCallback onRead,
    required NfcErrorCallback onError,
  }) async {
    final available = await checkAvailability();
    if (!available) {
      onError('nfc.unsupported');
      return;
    }

    if (_isSessionActive) {
      await stopSession();
    }

    _isSessionActive = true;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            NdefMessage? cachedMessage;
            if (defaultTargetPlatform == TargetPlatform.android) {
              final ndef = NdefAndroid.from(tag);
              cachedMessage = ndef?.cachedNdefMessage;
            } else if (defaultTargetPlatform == TargetPlatform.iOS) {
              final ndef = NdefIos.from(tag);
              cachedMessage = ndef?.cachedNdefMessage;
            }

            String foundId = 'ART-DEMO-01'; // Default demo card
            String rawContent = '';

            if (cachedMessage != null) {
              for (final record in cachedMessage.records) {
                try {
                  final payload = record.payload;
                  if (payload.isNotEmpty) {
                    final str = utf8.decode(payload, allowMalformed: true);
                    rawContent += '$str ';
                    if (str.contains('artisan=')) {
                      final uri = Uri.tryParse(str.substring(str.indexOf('http')));
                      if (uri != null && uri.queryParameters.containsKey('artisan')) {
                        foundId = uri.queryParameters['artisan']!;
                      }
                    } else if (str.contains('ART-DEMO-')) {
                      final match = RegExp(r'ART-DEMO-\d+').firstMatch(str);
                      if (match != null) {
                        foundId = match.group(0)!;
                      }
                    }
                  }
                } catch (_) {}
              }
            }

            await stopSession();
            onRead(foundId, rawContent);
          } catch (err) {
            await stopSession();
            onError('nfc.error');
          }
        },
      );
    } catch (e) {
      _isSessionActive = false;
      onError('nfc.error');
    }
  }

  Future<void> startWriteSession({
    required String artisanId,
    required VoidCallback onWritten,
    required NfcErrorCallback onError,
  }) async {
    final available = await checkAvailability();
    if (!available) {
      onError('nfc.unsupported');
      return;
    }

    if (_isSessionActive) {
      await stopSession();
    }

    _isSessionActive = true;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final uriBytes = utf8.encode('https://bot.le7rayfi.com/?artisan=$artisanId');
            final uriRecord = NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList([0x55]), // 'U'
              identifier: Uint8List(0),
              payload: Uint8List.fromList([0x00, ...uriBytes]),
            );

            final textBytes = utf8.encode(artisanId);
            final textRecord = NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList([0x54]), // 'T'
              identifier: Uint8List(0),
              payload: Uint8List.fromList([0x02, 0x65, 0x6E, ...textBytes]),
            );

            final message = NdefMessage(records: [uriRecord, textRecord]);

            if (defaultTargetPlatform == TargetPlatform.android) {
              final ndef = NdefAndroid.from(tag);
              if (ndef == null || !ndef.isWritable) {
                await stopSession();
                onError('nfc.error');
                return;
              }
              await ndef.writeNdefMessage(message);
            } else if (defaultTargetPlatform == TargetPlatform.iOS) {
              final ndef = NdefIos.from(tag);
              if (ndef == null || ndef.status != NdefStatusIos.readWrite) {
                await stopSession();
                onError('nfc.error');
                return;
              }
              await ndef.writeNdef(message);
            }

            await stopSession();
            onWritten();
          } catch (e) {
            await stopSession();
            onError('nfc.error');
          }
        },
      );
    } catch (e) {
      _isSessionActive = false;
      onError('nfc.error');
    }
  }

  Future<void> stopSession() async {
    if (_isSessionActive) {
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {}
      _isSessionActive = false;
    }
  }
}
