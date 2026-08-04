import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides an initial query to be seeded into the ChatScreen automatically.
final chatInitialQueryProvider = StateProvider<String?>((ref) => null);
