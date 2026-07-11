import 'dart:math';

/// Generates a short, collision-resistant-enough identifier for local objects.
///
/// Combines a microsecond timestamp with random bits, both base-36 encoded, so
/// ids are short, sortable-ish and unique for the scale this app operates at
/// (a handful of chains created by a single user).
String newId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = Random().nextInt(1 << 32);
  return '${now.toRadixString(36)}-${rand.toRadixString(36)}';
}
