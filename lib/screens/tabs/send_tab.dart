import 'package:flutter/material.dart';
import '../../services/node_service.dart';

class SendTab extends StatefulWidget {
  final double balance;
  final VoidCallback onSent;
  const SendTab({super.key, required this.balance, required this.onSent});

  @override
  State<SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<SendTab> {
  final _addrController = TextEditingController();
  final _amtController = TextEditingController();
  int _feeLevel = 1; // 0=low, 1=normal, 2=high
  String _message = '';
  bool _isError = false;
  bool _sending = false;

  final _feeLabels = ['Low', 'Normal', 'High'];
  final _feeRates = [1, 5, 20];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(20), children: [
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540), child: Card(
        child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF00C48C).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock, size: 12, color: Color(0xFF00C48C)),
              SizedBox(width: 4),
              Text('Signed locally — key never leaves device', style: TextStyle(fontSize: 11, color: Color(0xFF00C48C), fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 18),

          // Address
          Row(children: [
            const Text('Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {}, // TODO: Address book picker
              icon: const Icon(Icons.contacts, size: 14),
              label: const Text('Address Book', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ]),
          const SizedBox(height: 5),
          TextField(
            controller: _addrController,
            style: const TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 14),
            decoration: const InputDecoration(hintText: 'shrd1q...'),
          ),
          const SizedBox(height: 16),

          // Amount
          Row(children: [
            const Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () {
                final fee = _feeRates[_feeLevel] * 200 / 1e8;
                final max = (widget.balance - fee).clamp(0.0, double.infinity);
                _amtController.text = max.toStringAsFixed(8);
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: Text('MAX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            ),
          ]),
          const SizedBox(height: 5),
          TextField(
            controller: _amtController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 22, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: '0.00'),
          ),
          Text('Available: ${widget.balance.toStringAsFixed(8)} SHRD', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5))),
          const SizedBox(height: 16),

          // Fee
          const Text('Fee Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _feeLevel = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _feeLevel == i ? theme.colorScheme.primary : theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                    color: _feeLevel == i ? theme.colorScheme.primary.withOpacity(0.1) : null,
                  ),
                  child: Column(children: [
                    Text(_feeLabels[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _feeLevel == i ? theme.colorScheme.primary : null)),
                    Text('~${_feeRates[i]} shard/vB', style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5))),
                  ]),
                ),
              ),
            ),
          ))),
          const SizedBox(height: 16),

          // Message
          if (_message.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_isError ? const Color(0xFFFF4757) : const Color(0xFF00C48C)).withOpacity(0.1),
                border: Border.all(color: (_isError ? const Color(0xFFFF4757) : const Color(0xFF00C48C)).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_message, style: TextStyle(fontSize: 13, color: _isError ? const Color(0xFFFF4757) : const Color(0xFF00C48C))),
            ),
            const SizedBox(height: 12),
          ],

          // Send button
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _sending ? null : _doSend,
            child: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send SHRD'),
          )),
        ])),
      )),
    ]);
  }

  Future<void> _doSend() async {
    final addr = _addrController.text.trim();
    final amt = double.tryParse(_amtController.text) ?? 0;

    if (addr.isEmpty) { setState(() { _message = 'Enter a recipient address'; _isError = true; }); return; }
    if (amt <= 0) { setState(() { _message = 'Enter a valid amount'; _isError = true; }); return; }
    if (!NodeService.instance.isConnected) { setState(() { _message = 'Not connected to node'; _isError = true; }); return; }

    setState(() { _sending = true; _message = ''; });

    try {
      // For now use sendtoaddress via RPC (node's wallet)
      // TODO: Implement full client-side signing
      final txid = await NodeService.instance.rpc('sendtoaddress', [addr, amt]);
      setState(() { _message = 'Sent! TX: ${txid.toString().substring(0, 20)}...'; _isError = false; });
      _addrController.clear();
      _amtController.clear();
      widget.onSent();
    } catch (e) {
      setState(() { _message = e.toString().replaceFirst('Exception: ', ''); _isError = true; });
    }

    setState(() => _sending = false);
  }
}
