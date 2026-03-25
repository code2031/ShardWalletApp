# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShardWalletApp is a cross-platform **non-custodial** wallet for ShardCoin (SHRD) built with Flutter. It targets Android, iOS, Linux, macOS, Windows, and Web from a single codebase. Private keys are generated and stored on-device using `flutter_secure_storage` — the node is only used for blockchain data and broadcasting transactions.

## Build Commands

```bash
# Get dependencies
flutter pub get

# Run in debug (requires connected device/emulator)
flutter run

# Build web
flutter build web --release

# Build Linux desktop
flutter build linux --release

# Build Android APK
flutter build apk --release

# Build iOS (requires macOS + Xcode)
flutter build ios --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Run single test
flutter test test/widget_test.dart
```

**Dependencies for Linux build**: `apt install libgtk-3-dev libsecret-1-dev libjsoncpp-dev lld clang cmake ninja-build pkg-config`

## Architecture

### Layer Structure

```
lib/
  main.dart              — App entry, theme, root widget (checks wallet existence)
  crypto/                — Cryptographic primitives
    bech32.dart          — Custom bech32 encoder/decoder for 'shrd' prefix
  services/              — Business logic singletons
    wallet_service.dart  — Key management (BIP39/BIP32, address derivation)
    node_service.dart    — JSON-RPC communication with shardcoind
  screens/               — Full-page UI
    welcome_screen.dart  — Wallet creation/restore/node setup flow (4 steps)
    home_screen.dart     — Main app shell (sidebar on desktop, bottom nav on mobile)
    tabs/                — Content pages within home
      dashboard_tab.dart — Balance, stats, quick actions, recent transactions
      send_tab.dart      — Send form with fee selector and max button
      receive_tab.dart   — QR code display and address copy
      history_tab.dart   — Full transaction list with CSV export
      settings_tab.dart  — Node config, seed backup, wallet reset
  widgets/               — Reusable components
    stat_card.dart       — Balance/block/difficulty display card
    tx_list_item.dart    — Transaction row with detail dialog
```

### Key Design Decisions

- **Singleton services**: `WalletService.instance` and `NodeService.instance` are global singletons accessed throughout the app
- **Key derivation path**: `m/84'/1000'/0'/0/*` (BIP84, coin type 1000 for ShardCoin)
- **Bech32 prefix**: `shrd` for mainnet, `rshrd` for regtest
- **Secure storage**: Mnemonic stored via `flutter_secure_storage` (Keychain on iOS, Keystore on Android, libsecret on Linux)
- **No state management library**: Uses `StatefulWidget` + `setState` throughout. Consider adding Riverpod/Bloc if complexity grows.

### Node Communication

`NodeService` sends JSON-RPC POST requests to `shardcoind`. Config (URL, user, pass, wallet name) persisted via `SharedPreferences`. Key RPC calls:

- `getblockchaininfo` — chain status
- `getbalance` — wallet balance
- `listtransactions` — transaction history
- `getnewaddress` — (node wallet mode)
- `importaddress` — watch-only address registration
- `sendrawtransaction` — broadcast signed transactions

Auto-refresh every 15 seconds when connected.

### ShardCoin Network Parameters

```
Bech32 HRP:      shrd
BIP44 coin type: 1000
Derivation:      m/84'/1000'/0'/0/*
Mainnet RPC:     http://127.0.0.1:7332
Regtest RPC:     http://127.0.0.1:17443
```
