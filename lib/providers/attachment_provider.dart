// lib/providers/attachment_provider.dart
//
// Shared Riverpod state for attachments + selected AI model.
// Used by HomeScreen, ChatScreen, Settings, History, MessageBox flows.
// ------------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/attachment_model.dart';
import '../core/config.dart' as app_config;
import '../screens/widgets/attachment_picker_sheet.dart'
    show kMaxAttachmentSizeBytes;

/// Max attachment size exposed for Settings / UI copy.
final maxAttachmentSizeProvider = Provider<int>(
  (_) => kMaxAttachmentSizeBytes,
);

/// Currently selected AI model (shared across chat + settings).
class SelectedModelNotifier extends StateNotifier<app_config.AiModel> {
  SelectedModelNotifier() : super(app_config.Config.defaultModel);

  void selectByName(String name) {
    final model = app_config.Config.getModelByName(name);
    if (model != null) state = model;
  }

  void select(app_config.AiModel model) {
    state = model;
  }

  bool get supportsVision => state.supportsVision;
}

final selectedModelProvider =
    StateNotifierProvider<SelectedModelNotifier, app_config.AiModel>(
  (ref) => SelectedModelNotifier(),
);

/// Pending compose attachments (optional shared draft state).
class PendingAttachmentsNotifier extends StateNotifier<List<Attachment>> {
  PendingAttachmentsNotifier() : super(const []);

  void add(Attachment attachment) {
    state = [...state, attachment];
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    final next = List<Attachment>.from(state)..removeAt(index);
    state = next;
  }

  void clear() => state = const [];

  void replaceAll(List<Attachment> attachments) {
    state = List<Attachment>.unmodifiable(attachments);
  }

  int get totalBytes => state.fold(0, (sum, a) => sum + a.sizeBytes);

  bool get hasPending => state.isNotEmpty;
}

final pendingAttachmentsProvider =
    StateNotifierProvider<PendingAttachmentsNotifier, List<Attachment>>(
  (ref) => PendingAttachmentsNotifier(),
);

/// Whether the selected model can accept image attachments.
final visionCapableProvider = Provider<bool>((ref) {
  return ref.watch(selectedModelProvider).supportsVision;
});

/// Available models from Config.
final modelsProvider = Provider<List<app_config.AiModel>>(
  (_) => app_config.Config.models,
);

/// Vision-capable subset from Config.
final visionModelsProvider = Provider<List<app_config.AiModel>>(
  (_) => app_config.Config.visionCapableModels,
);
