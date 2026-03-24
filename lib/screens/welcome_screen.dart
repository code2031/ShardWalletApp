import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import '../services/node_service.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onWalletCreated;
  const WelcomeScreen({super.key, required this.onWalletCreated});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _step = 0; // 0=welcome, 1=create(show seed), 2=restore, 3=node setup
  String? _mnemonic;
  final _seedController = TextEditingController();
  final _urlController = TextEditingController(text: 'http://127.0.0.1:7332');
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _walletController = TextEditingController();
  String _error = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildWelcome();
      case 1: return _buildShowSeed();
      case 2: return _buildRestore();
      case 3: return _buildNodeSetup();
      default: return _buildWelcome();
    }
  }

  Widget _buildWelcome() {
    return Column(
      key: const ValueKey(0),
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C5CE7), Color(0xFFA78BFA)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF7C5CE7).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: const Center(child: Text('S', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        const SizedBox(height: 28),
        const Text('ShardWallet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Non-custodial wallet for ShardCoin.\nYour keys, your coins.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5), height: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFF00C48C).withOpacity(0.12), borderRadius: BorderRadius.circular(100)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock, size: 14, color: Color(0xFF00C48C)),
            SizedBox(width: 5),
            Text('Client-side key management', style: TextStyle(fontSize: 12, color: Color(0xFF00C48C), fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 36),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () async {
            setState(() => _loading = true);
            _mnemonic = await WalletService.instance.createWallet();
            setState(() { _step = 1; _loading = false; });
          },
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create New Wallet'),
        )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => setState(() => _step = 2),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
            foregroundColor: Colors.white.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Restore from Seed'),
        )),
      ],
    );
  }

  Widget _buildShowSeed() {
    final words = _mnemonic!.split(' ');
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Seed Phrase', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Write down these 12 words in order. This is the ONLY way to recover your wallet.', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5), height: 1.5)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E20),
            border: Border.all(color: const Color(0xFF252545)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(words.length, (i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                border: Border.all(color: const Color(0xFF252545)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: RichText(text: TextSpan(children: [
                TextSpan(text: '${i + 1}. ', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
                TextSpan(text: words[i], style: const TextStyle(fontSize: 14, color: Color(0xFF7C5CE7), fontWeight: FontWeight.w500)),
              ])),
            )),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _mnemonic!));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)));
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy to clipboard'),
          style: TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.4)),
        )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFA500).withOpacity(0.1), border: Border.all(color: const Color(0xFFFFA500).withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.warning_amber, size: 18, color: Color(0xFFFFA500)),
            SizedBox(width: 8),
            Expanded(child: Text('Never share your seed phrase. Anyone with it can steal your funds.', style: TextStyle(fontSize: 12, color: Color(0xFFFFA500)))),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text("I've Written It Down"),
        )),
        Center(child: TextButton(
          onPressed: () => setState(() => _step = 0),
          child: Text('Back', style: TextStyle(color: Colors.white.withOpacity(0.4))),
        )),
      ],
    );
  }

  Widget _buildRestore() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Restore Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Enter your 12-word seed phrase.', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 20),
        TextField(
          controller: _seedController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontFamily: 'IBM Plex Mono', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your 12 words separated by spaces...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_error, style: const TextStyle(color: Color(0xFFFF4757), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () async {
            final ok = await WalletService.instance.restoreWallet(_seedController.text);
            if (ok) {
              setState(() { _step = 3; _error = ''; });
            } else {
              setState(() => _error = 'Invalid seed phrase');
            }
          },
          child: const Text('Restore Wallet'),
        )),
        Center(child: TextButton(
          onPressed: () => setState(() { _step = 0; _error = ''; }),
          child: Text('Back', style: TextStyle(color: Colors.white.withOpacity(0.4))),
        )),
      ],
    );
  }

  Widget _buildNodeSetup() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Connect to Node', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Connect to your ShardCoin node. Keys stay in your device.', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 20),
        _field('RPC URL', _urlController),
        Row(children: [
          Expanded(child: _field('Username', _userController)),
          const SizedBox(width: 10),
          Expanded(child: _field('Password', _passController, obscure: true)),
        ]),
        _field('Wallet Name (optional)', _walletController),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () async {
            final node = NodeService.instance;
            node.config.url = _urlController.text.trim().isEmpty ? 'http://127.0.0.1:7332' : _urlController.text.trim();
            node.config.user = _userController.text.trim();
            node.config.pass = _passController.text.trim();
            node.config.wallet = _walletController.text.trim();
            await node.saveConfig();
            widget.onWalletCreated();
          },
          child: const Text('Connect'),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => widget.onWalletCreated(),
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.15)), foregroundColor: Colors.white.withOpacity(0.6)),
          child: const Text('Skip (Offline Mode)'),
        )),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.4), letterSpacing: 0.8)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontFamily: 'IBM Plex Mono', fontSize: 14),
          decoration: InputDecoration(hintStyle: TextStyle(color: Colors.white.withOpacity(0.15))),
        ),
      ]),
    );
  }
}
