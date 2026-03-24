import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../../services/node_service.dart';

class SettingsTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const SettingsTab({super.key, required this.onRefresh});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _walCtrl = TextEditingController();
  bool _showSeed = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    final cfg = NodeService.instance.config;
    _urlCtrl.text = cfg.url;
    _userCtrl.text = cfg.user;
    _passCtrl.text = cfg.pass;
    _walCtrl.text = cfg.wallet;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletService.instance;
    return ListView(padding: const EdgeInsets.all(20), children: [
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540), child: Column(children: [
        // Node Connection
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Node Connection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _field('RPC URL', _urlCtrl),
          Row(children: [
            Expanded(child: _field('Username', _userCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _field('Password', _passCtrl, obscure: true)),
          ]),
          _field('Wallet Name', _walCtrl),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final node = NodeService.instance;
              node.config.url = _urlCtrl.text.trim().isEmpty ? 'http://127.0.0.1:7332' : _urlCtrl.text.trim();
              node.config.user = _userCtrl.text.trim();
              node.config.pass = _passCtrl.text.trim();
              node.config.wallet = _walCtrl.text.trim();
              await node.saveConfig();
              widget.onRefresh();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
            },
            child: const Text('Save & Reconnect'),
          )),
        ]))),
        const SizedBox(height: 16),

        // Seed Backup
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Seed Phrase Backup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFFA500).withOpacity(0.1), border: Border.all(color: const Color(0xFFFFA500).withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.warning_amber, size: 16, color: Color(0xFFFFA500)),
              SizedBox(width: 8),
              Expanded(child: Text('Never share your seed phrase.', style: TextStyle(fontSize: 12, color: Color(0xFFFFA500)))),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => setState(() => _showSeed = !_showSeed),
            child: Text(_showSeed ? 'Hide Seed Phrase' : 'Show Seed Phrase'),
          )),
          if (_showSeed && wallet.mnemonicWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: List.generate(wallet.mnemonicWords.length, (i) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${i + 1}. ${wallet.mnemonicWords[i]}', style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              ),
            )),
          ],
          const SizedBox(height: 16),
          const Text('Addresses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...wallet.addresses.take(10).toList().asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('#${e.key}  ${e.value}', style: const TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 11), overflow: TextOverflow.ellipsis),
            ),
          )),
        ]))),
        const SizedBox(height: 16),

        // Danger zone
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Danger Zone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFF4757))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Delete Wallet?'),
                content: const Text('This will delete your encrypted keys from this device. Make sure you have your seed phrase backed up!'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFFF4757)))),
                ],
              ));
              if (confirm == true) {
                await WalletService.instance.deleteWallet();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4757)),
            child: const Text('Reset Wallet'),
          )),
        ]))),
      ])),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5))),
        const SizedBox(height: 4),
        TextField(controller: ctrl, obscureText: obscure, style: const TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 14)),
      ]),
    );
  }
}
