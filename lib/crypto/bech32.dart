import 'dart:typed_data';

class Bech32 {
  static const _charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  static int _polymod(List<int> values) {
    const gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
    int chk = 1;
    for (final v in values) {
      final b = chk >> 25;
      chk = ((chk & 0x1ffffff) << 5) ^ v;
      for (int i = 0; i < 5; i++) {
        if ((b >> i) & 1 == 1) chk ^= gen[i];
      }
    }
    return chk;
  }

  static List<int> _hrpExpand(String hrp) {
    final result = <int>[];
    for (int i = 0; i < hrp.length; i++) {
      result.add(hrp.codeUnitAt(i) >> 5);
    }
    result.add(0);
    for (int i = 0; i < hrp.length; i++) {
      result.add(hrp.codeUnitAt(i) & 31);
    }
    return result;
  }

  static List<int> _createChecksum(String hrp, List<int> data) {
    final values = _hrpExpand(hrp) + data + [0, 0, 0, 0, 0, 0];
    final pm = _polymod(values) ^ 1;
    return List.generate(6, (i) => (pm >> (5 * (5 - i))) & 31);
  }

  static List<int> _convertBits(List<int> data, int fromBits, int toBits, bool pad) {
    int acc = 0;
    int bits = 0;
    final result = <int>[];
    final maxv = (1 << toBits) - 1;

    for (final d in data) {
      acc = (acc << fromBits) | d;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad && bits > 0) {
      result.add((acc << (toBits - bits)) & maxv);
    }

    return result;
  }

  static String encode(String hrp, int version, Uint8List program) {
    final data = [version] + _convertBits(program.toList(), 8, 5, true);
    final checksum = _createChecksum(hrp, data);
    final combined = data + checksum;
    return '$hrp${1}${combined.map((d) => _charset[d]).join()}';
  }

  static ({String hrp, int version, Uint8List program})? decode(String str) {
    final pos = str.lastIndexOf('1');
    if (pos < 1) return null;

    final hrp = str.substring(0, pos).toLowerCase();
    final dp = str.substring(pos + 1);

    final data = <int>[];
    for (final c in dp.split('')) {
      final idx = _charset.indexOf(c.toLowerCase());
      if (idx < 0) return null;
      data.add(idx);
    }

    final version = data[0];
    final convData = data.sublist(1, data.length - 6);
    final program = _convertBits(convData, 5, 8, false);

    return (hrp: hrp, version: version, program: Uint8List.fromList(program));
  }
}
