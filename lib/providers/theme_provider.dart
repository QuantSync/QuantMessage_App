import 'package:flutter_riverpod/flutter_riverpod.dart';

final motionProvider = StateProvider<bool>((ref) => true); // true = System (Normal), false = Reduced
