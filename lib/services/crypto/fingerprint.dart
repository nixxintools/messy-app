import '../../core/bytes.dart';

/// 6-word verification phrase for a contact pair — docs/SECURITY.md §3.
/// Both devices derive the same words from SHA-256 over the two X25519
/// public keys in sorted order, so the phrases match iff no one is in the
/// middle.
const _words = [
  'amber', 'anvil', 'aspen', 'badge', 'basil', 'birch', 'blaze', 'brook',
  'candle', 'canyon', 'cedar', 'cliff', 'clover', 'comet', 'coral', 'crane',
  'delta', 'drift', 'dune', 'ember', 'fable', 'falcon', 'fern', 'flint',
  'gale', 'glade', 'grove', 'harbor', 'hazel', 'heron', 'iris', 'ivory',
  'jasper', 'juniper', 'kite', 'lagoon', 'lark', 'lotus', 'maple', 'marble',
  'meadow', 'mesa', 'moss', 'nectar', 'nine', 'oasis', 'onyx', 'orchid',
  'otter', 'pearl', 'pine', 'plume', 'quartz', 'raven', 'reef', 'ridge',
  'sage', 'slate', 'summit', 'thistle', 'tide', 'violet', 'willow', 'wren',
];

String fingerprintPhrase(List<int> pubA, List<int> pubB) {
  final a = hexEncode(pubA);
  final b = hexEncode(pubB);
  final sorted = a.compareTo(b) <= 0 ? [pubA, pubB] : [pubB, pubA];
  final digest = sha256Bytes(concatBytes(sorted));
  return List.generate(6, (i) => _words[digest[i] % _words.length]).join(' ');
}
