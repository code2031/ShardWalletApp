import 'dart:convert';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crypto/bech32.dart';

class WalletService {
  static final WalletService instance = WalletService._();
  WalletService._();

  final _storage = const FlutterSecureStorage();
  static const _mnemonicKey = 'sw_mnemonic';
  static const _coinType = 1000;
  static const _bech32Hrp = 'shrd';

  String? _mnemonic;
  bip32.BIP32? _root;
  List<String> _addresses = [];
  List<Uint8List> _publicKeys = [];
  List<Uint8List> _privateKeys = [];
  int _addressCount = 20;
  int _receiveIndex = 0;

  bool get isUnlocked => _mnemonic != null;
  List<String> get addresses => _addresses;
  String get currentAddress => _addresses.isNotEmpty ? _addresses[_receiveIndex] : '';
  String? get mnemonic => _mnemonic;
  int get receiveIndex => _receiveIndex;

  Future<bool> hasWallet() async {
    final stored = await _storage.read(key: _mnemonicKey);
    return stored != null;
  }

  Future<String> createWallet() async {
    _mnemonic = bip39.generateMnemonic();
    await _storage.write(key: _mnemonicKey, value: _mnemonic);
    _deriveKeys();
    return _mnemonic!;
  }

  Future<bool> restoreWallet(String mnemonic) async {
    if (!bip39.validateMnemonic(mnemonic.trim().toLowerCase())) {
      return false;
    }
    _mnemonic = mnemonic.trim().toLowerCase();
    await _storage.write(key: _mnemonicKey, value: _mnemonic);
    _deriveKeys();
    return true;
  }

  Future<bool> unlock() async {
    final stored = await _storage.read(key: _mnemonicKey);
    if (stored == null) return false;
    _mnemonic = stored;
    _deriveKeys();
    return true;
  }

  void lock() {
    _mnemonic = null;
    _root = null;
    _addresses.clear();
    _publicKeys.clear();
    _privateKeys.clear();
  }

  Future<void> deleteWallet() async {
    await _storage.deleteAll();
    lock();
  }

  void _deriveKeys() {
    final seed = bip39.mnemonicToSeed(_mnemonic!);
    _root = bip32.BIP32.fromSeed(seed);
    _addresses = [];
    _publicKeys = [];
    _privateKeys = [];

    for (int i = 0; i < _addressCount; i++) {
      final child = _root!.derivePath("m/84'/$_coinType'/0'/0/$i");
      final pubkey = child.publicKey;
      final privkey = child.privateKey!;
      final address = _pubkeyToAddress(pubkey);
      _addresses.add(address);
      _publicKeys.add(pubkey);
      _privateKeys.add(privkey);
    }
  }

  String _pubkeyToAddress(Uint8List pubkey) {
    final sha = sha256.convert(pubkey).bytes;
    final ripemd = RIPEMD160Digest();
    final hash160 = Uint8List(20);
    ripemd.update(Uint8List.fromList(sha), 0, sha.length);
    ripemd.doFinal(hash160, 0);
    return Bech32.encode(_bech32Hrp, 0, hash160);
  }

  String nextAddress() {
    _receiveIndex = (_receiveIndex + 1) % _addresses.length;
    return currentAddress;
  }

  Uint8List? getPrivateKey(String address) {
    final idx = _addresses.indexOf(address);
    if (idx < 0) return null;
    return _privateKeys[idx];
  }

  Uint8List? getPublicKey(String address) {
    final idx = _addresses.indexOf(address);
    if (idx < 0) return null;
    return _publicKeys[idx];
  }

  List<String> get mnemonicWords => _mnemonic?.split(' ') ?? [];
}
