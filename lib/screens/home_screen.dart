import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import '../services/node_service.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/send_tab.dart';
import 'tabs/receive_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  Timer? _refreshTimer;
  double _balance = 0;
  Map<String, dynamic> _chainInfo = {};
  List<Map<String, dynamic>> _transactions = [];
  bool _connected = false;
  bool _unlocked = false;

  final _titles = ['Account', 'Send', 'Receive', 'History', 'Settings'];
  final _icons = [Icons.account_balance_wallet, Icons.arrow_upward, Icons.arrow_downward, Icons.receipt_long, Icons.settings];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NodeService.instance.loadConfig();
    final ok = await WalletService.instance.unlock();
    setState(() => _unlocked = ok);
    _refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    // Import addresses in background
    _importAddresses();
  }

  Future<void> _importAddresses() async {
    for (final addr in WalletService.instance.addresses) {
      await NodeService.instance.importAddress(addr);
    }
  }

  Future<void> _refresh() async {
    try {
      final info = await NodeService.instance.getBlockchainInfo();
      final bal = await NodeService.instance.getBalance();
      List<Map<String, dynamic>> txs = [];
      try { txs = await NodeService.instance.getTransactions(); } catch (_) {}
      if (mounted) {
        setState(() { _chainInfo = info; _balance = bal; _transactions = txs; _connected = true; });
      }
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    if (isWide) {
      return Scaffold(
        body: Row(children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ]),
      );
    }

    return Scaffold(
      body: _buildContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: List.generate(5, (i) => NavigationDestination(
          icon: Icon(_icons[i]),
          label: _titles[i],
        )),
      ),
    );
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    return Container(
      width: 250,
      color: const Color(0xFF16162A),
      child: Column(children: [
        // Brand
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(9)),
              child: const Center(child: Text('S', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ShardWallet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Non-custodial', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
            ]),
          ]),
        ),
        Container(height: 1, color: const Color(0xFF252545)),
        // Balance
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.4), letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text('${_formatAmount(_balance)} SHRD', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'IBM Plex Mono')),
          ]),
        ),
        Container(height: 1, color: const Color(0xFF252545)),
        // Nav items
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          ...List.generate(4, (i) => _sidebarItem(i)),
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), color: const Color(0xFF252545)),
          _sidebarItem(4),
        ])),
        // Status
        Container(height: 1, color: const Color(0xFF252545)),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _connected ? const Color(0xFF00C48C) : const Color(0xFF999999),
                boxShadow: _connected ? [BoxShadow(color: const Color(0xFF00C48C).withOpacity(0.5), blurRadius: 6)] : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _connected ? '${_chainInfo['chain'] ?? ''} · block ${_chainInfo['blocks'] ?? ''}' : 'Offline',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _sidebarItem(int index) {
    final selected = _currentTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1F1F3A) : null,
            border: Border(left: BorderSide(color: selected ? const Color(0xFF7C5CE7) : Colors.transparent, width: 3)),
          ),
          child: Row(children: [
            Icon(_icons[index], size: 18, color: selected ? Colors.white : Colors.white.withOpacity(0.4)),
            const SizedBox(width: 12),
            Text(_titles[index], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : Colors.white.withOpacity(0.4))),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
        ),
        child: Row(children: [
          Text(_titles[_currentTab], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (_connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00C48C).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00C48C))),
                const SizedBox(width: 5),
                Text('Block ${_chainInfo['blocks'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Color(0xFF00C48C), fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ),
      // Body
      Expanded(child: IndexedStack(
        index: _currentTab,
        children: [
          DashboardTab(balance: _balance, chainInfo: _chainInfo, transactions: _transactions, connected: _connected, onNav: (i) => setState(() => _currentTab = i)),
          SendTab(balance: _balance, onSent: _refresh),
          ReceiveTab(),
          HistoryTab(transactions: _transactions),
          SettingsTab(onRefresh: _refresh),
        ],
      )),
    ]);
  }

  String _formatAmount(double n) {
    if (n == n.truncateToDouble() && n.abs() < 10000) return n.toStringAsFixed(2);
    return n.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '.00');
  }
}
