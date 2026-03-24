import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/tx_list_item.dart';

class HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const HistoryTab({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Text('All Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _exportCSV(context),
              icon: const Icon(Icons.download, size: 14),
              label: const Text('CSV', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ]),
        ),
        const Divider(height: 1),
        if (transactions.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey, fontSize: 13))))
        else
          ...transactions.map((tx) => TxListItem(tx: tx, showDetail: true)),
      ])),
    ]);
  }

  void _exportCSV(BuildContext context) {
    if (transactions.isEmpty) return;
    final header = 'Date,Type,Amount,Address,TXID,Confirmations,Fee\n';
    final rows = transactions.map((tx) {
      final date = tx['time'] != null ? DateTime.fromMillisecondsSinceEpoch((tx['time'] as num).toInt() * 1000).toIso8601String() : '';
      return '"$date","${tx['category']}","${tx['amount']}","${tx['address'] ?? 'coinbase'}","${tx['txid'] ?? ''}","${tx['confirmations'] ?? 0}","${tx['fee'] ?? ''}"';
    }).join('\n');
    Clipboard.setData(ClipboardData(text: header + rows));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard'), duration: Duration(seconds: 2)));
  }
}
