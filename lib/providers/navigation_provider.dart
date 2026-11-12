import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected tab in the bottom navigation. Kept in Riverpod so any tab can
/// navigate to a sibling (for example "See all" jumping to Transactions).
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
