import 'package:flutter/material.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/tx_list_item.dart';

class DashboardTab extends StatelessWidget {
  final double balance;
  final Map<String, dynamic> chainInfo;
  final List<Map<String, dynamic>> transactions;
  final bool connected;
  final ValueChanged<int> onNav;

  const DashboardTab({super.key, required this.balance, required this.chainInfo, required this.transactions, required this.connected, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      // Stats
      LayoutBuilder(builder: (ctx, constraints) {
        final wide = constraints.maxWidth > 500;
        final cards = [
          StatCard(label: 'TOTAL BALANCE', value: _fmt(balance), sub: 'SHRD'),
          StatCard(label: 'BLOCK HEIGHT', value: '${chainInfo['blocks'] ?? '-'}', sub: '${chainInfo['chain'] ?? '-'}'),
          StatCard(label: 'DIFFICULTY', value: _fmtDiff(), sub: 'Current'),
        ];
        if (wide) {
          return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList());
        }
        return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList());
      }),

      const SizedBox(height: 16),

      // Quick actions
      Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: () => onNav(1),
          icon: const Icon(Icons.arrow_upward, size: 18),
          label: const Text('Send'),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => onNav(2),
          icon: const Icon(Icons.arrow_downward, size: 18),
          label: const Text('Receive'),
        )),
      ]),

      const SizedBox(height: 24),

      // Recent Transactions
      Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Text('Recent Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
              child: Text('${transactions.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
            ),
          ]),
        ),
        const Divider(height: 1),
        if (transactions.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No transactions yet', style: TextStyle(fontSize: 13, color: Colors.grey))))
        else
          ...transactions.take(5).map((tx) => TxListItem(tx: tx)),
        if (transactions.length > 5)
          TextButton(onPressed: () => onNav(3), child: const Text('View all transactions')),
      ])),
    ]);
  }

  String _fmt(double n) {
    if (n == n.truncateToDouble() && n.abs() < 10000) return n.toStringAsFixed(2);
    return n.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '.00');
  }

  String _fmtDiff() {
    final d = chainInfo['difficulty'];
    if (d == null) return '-';
    return (d as num).toDouble().toStringAsExponential(2);
  }
}
