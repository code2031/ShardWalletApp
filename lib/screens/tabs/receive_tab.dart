import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/wallet_service.dart';

class ReceiveTab extends StatefulWidget {
  const ReceiveTab({super.key});

  @override
  State<ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends State<ReceiveTab> {
  String _address = '';

  @override
  void initState() {
    super.initState();
    _address = WalletService.instance.currentAddress;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00C48C).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock, size: 12, color: Color(0xFF00C48C)),
                SizedBox(width: 4),
                Text('Address derived locally from your seed', style: TextStyle(fontSize: 11, color: Color(0xFF00C48C), fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 20),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              ),
              child: QrImageView(
                data: _address,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF16162A)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF16162A)),
              ),
            ),
            const SizedBox(height: 18),

            // Address
            GestureDetector(
              onTap: _copy,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _address.isEmpty ? 'No address' : _address,
                  style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 13, color: theme.colorScheme.primary, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Tap address to copy', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color?.withOpacity(0.4))),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _address = WalletService.instance.nextAddress());
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('New Address'),
              )),
            ]),
          ]),
        )),
      )),
    ]);
  }

  void _copy() {
    if (_address.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _address));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied to clipboard'), duration: Duration(seconds: 2)));
    }
  }
}
