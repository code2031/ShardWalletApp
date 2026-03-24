import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TxListItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool showDetail;

  const TxListItem({super.key, required this.tx, this.showDetail = false});

  @override
  Widget build(BuildContext context) {
    final cat = tx['category'] ?? '';
    final isIn = cat == 'receive' || cat == 'generate' || cat == 'immature';
    final isMined = cat == 'generate' || cat == 'immature';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final addr = tx['address'] ?? 'coinbase';
    final time = tx['time'] as num?;
    final confs = tx['confirmations'] ?? 0;

    return InkWell(
      onTap: showDetail ? () => _showDetailDialog(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isMined
                  ? const Color(0xFFFFA500).withOpacity(0.1)
                  : isIn
                      ? const Color(0xFF00C48C).withOpacity(0.1)
                      : const Color(0xFFFF4757).withOpacity(0.1),
            ),
            child: Icon(
              isMined ? Icons.diamond : (isIn ? Icons.arrow_downward : Icons.arrow_upward),
              size: 18,
              color: isMined ? const Color(0xFFFFA500) : (isIn ? const Color(0xFF00C48C) : const Color(0xFFFF4757)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMined ? 'Mined' : (isIn ? 'Received' : 'Sent'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(addr, style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4)), overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          // Amount + time
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isIn ? '+' : '-'}${_fmt(amount.abs())}',
              style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 13, fontWeight: FontWeight.w600, color: isIn ? const Color(0xFF00C48C) : const Color(0xFFFF4757)),
            ),
            Text(_fmtTime(time), style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4))),
          ]),
        ]),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Transaction Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row(ctx, 'Type', tx['category'] ?? '-'),
        _row(ctx, 'Amount', '${tx['amount']} SHRD'),
        _row(ctx, 'Address', tx['address'] ?? 'coinbase', copyable: true),
        _row(ctx, 'TXID', tx['txid'] ?? '-', copyable: true),
        _row(ctx, 'Confirmations', '${tx['confirmations'] ?? 0}'),
        _row(ctx, 'Block', tx['blockhash'] ?? 'unconfirmed'),
        _row(ctx, 'Time', tx['time'] != null ? DateTime.fromMillisecondsSinceEpoch((tx['time'] as num).toInt() * 1000).toString() : '-'),
        if (tx['fee'] != null) _row(ctx, 'Fee', '${tx['fee']} SHRD'),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }

  Widget _row(BuildContext context, String key, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(key, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontWeight: FontWeight.w500))),
        Expanded(child: GestureDetector(
          onTap: copyable ? () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
          } : null,
          child: Text(value, style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 11, color: copyable ? Theme.of(context).colorScheme.primary : null)),
        )),
      ]),
    );
  }

  String _fmt(double n) {
    if (n == n.truncateToDouble() && n.abs() < 10000) return n.toStringAsFixed(2);
    return n.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '.00');
  }

  String _fmtTime(num? ts) {
    if (ts == null) return '-';
    final diff = (DateTime.now().millisecondsSinceEpoch / 1000 - ts).toInt();
    if (diff < 60) return 'Just now';
    if (diff < 3600) return '${diff ~/ 60}m ago';
    if (diff < 86400) return '${diff ~/ 3600}h ago';
    return DateTime.fromMillisecondsSinceEpoch(ts.toInt() * 1000).toString().substring(0, 10);
  }
}
