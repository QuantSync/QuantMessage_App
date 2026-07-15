// lib/core/chat_message.dart
//
// QuantMessage — Chat data models
// Synchronized with:
// • Supabase 'chat_messages' table schema
// • QuantSpaceApi (Flowise responses)
// • UploadService (Attachment handling)
// • MessageBox (Local attachment management)
// • HistoryScreen (Data retrieval)
// • ChatScreen & IncognitoScreen (Real-time interaction)
// ------------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'attachment_model.dart';

/// The single source of truth for a chat message.
/// Handles the mapping between the Supabase PostgreSQL database
/// and the Flutter UI.
class ChatMessage {
  // ═══════════════════════════════════════════════════════════════════════
  // DATABASE IDENTIFIERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Primary key from Supabase (null for unsaved messages)
  final String? id;

  /// Groups messages into one chat session
  final String conversationId;

  /// UUID of the user or 'agent' / 'ghost_agent' / 'system'
  final String senderId;

  /// Timestamp for sorting in HistoryScreen
  final DateTime createdAt;

  // ═══════════════════════════════════════════════════════════════════════
  // CONTENT
  // ═══════════════════════════════════════════════════════════════════════

  /// The actual message content
  final String text;

  /// UI helper: true if sender is the user
  final bool isUser;

  /// The AI model used (e.g., 'GPT-4o', 'QuantCore 1.0')
  final String modelName;

  /// Attachments (images, PDFs, docs) included with the message
  final List<Attachment> attachments;

  /// True while AI is still streaming the response
  final bool isStreaming;

  /// Optional metadata for storing extra context
  /// (e.g., error info, generation params, attachment URLs)
  final Map<String, dynamic>? metadata;

  ChatMessage({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    required this.text,
    required this.isUser,
    this.modelName = "QuantCore",
    this.attachments = const [],
    this.isStreaming = false,
    this.metadata,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // SUPABASE INTEGRATION (Serialization)
  // ═══════════════════════════════════════════════════════════════════════

  /// Converts a Supabase database row (Map) into a ChatMessage object.
  /// Used in HistoryScreen.
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Parse attachments from metadata if stored
    final meta = map['metadata'] as Map<String, dynamic>?;
    final attachmentList = <Attachment>[];

    if (meta != null && meta['attachments'] is List) {
      for (final item in (meta['attachments'] as List)) {
        if (item is Map<String, dynamic>) {
          try {
            attachmentList.add(Attachment.fromJson(item));
          } catch (e) {
            debugPrint('Failed to parse attachment: $e');
          }
        }
      }
    }

    return ChatMessage(
      id: map['id']?.toString(),
      conversationId: map['conversation_id'] ?? '',
      senderId: map['sender_uuid'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      text: map['content'] ?? '',
      isUser: map['role'] == 'user',
      modelName: meta?['model'] ?? 'QuantCore',
      attachments: attachmentList,
      isStreaming: false, // Always false when loading from DB
      metadata: meta,
    );
  }

  /// Converts a ChatMessage object into a Map for Supabase insertion.
  /// Used in ChatScreen and IncognitoScreen during _handleSend.
  Map<String, dynamic> toMap() {
    // Build metadata with attachments as JSON
    final Map<String, dynamic> baseMeta = {
      'model': modelName,
      'attachment_count': attachments.length,
    };

    // Merge with any existing metadata
    if (metadata != null) {
      baseMeta.addAll(metadata!);
    }

    // Serialize attachments (only metadata, not bytes)
    if (attachments.isNotEmpty) {
      baseMeta['attachments'] =
          attachments.map((a) => a.toJson()).toList();
    }

    return {
      'conversation_id': conversationId,
      'sender_uuid': senderId,
      'role': isUser ? 'user' : 'agent',
      'content': text,
      'created_at': createdAt.toIso8601String(),
      'metadata': baseMeta,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI LOGIC GETTERS
  // ═══════════════════════════════════════════════════════════════════════

  /// True if the message contains any files/images.
  bool get hasAttachments => attachments.isNotEmpty;

  /// True if the message contains actual text (ignoring whitespace).
  bool get hasText => text.trim().isNotEmpty;

  /// True if the message is an error message (from 'system' sender).
  bool get isError => senderId == 'system' || senderId == 'ghost_system';

  /// True if the message has both text and attachments.
  bool get hasTextAndAttachments => hasText && hasAttachments;

  /// Number of attachments.
  int get attachmentCount => attachments.length;

  /// Total size of all attachments in bytes.
  int get totalAttachmentSize =>
      attachments.fold(0, (sum, a) => sum + a.sizeBytes);

  /// Human-readable total size of attachments.
  String get totalAttachmentSizeFormatted {
    final bytes = totalAttachmentSize;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// True if all attachments have been uploaded successfully.
  bool get allAttachmentsReady =>
      attachments.isEmpty || attachments.every((a) => a.isReady);

  /// True if any attachment is currently uploading.
  bool get hasUploadingAttachments =>
      attachments.any((a) => a.status == UploadStatus.uploading);

  /// True if any attachment failed to upload.
  bool get hasFailedAttachments =>
      attachments.any((a) => a.status == UploadStatus.failed);

  // ═══════════════════════════════════════════════════════════════════════
  // PROMPT BUILDING (For AI Multimodal Processing)
  // ═══════════════════════════════════════════════════════════════════════

  /// Builds the full prompt with attachment URLs appended.
  /// Used when sending to the AI.
  String get promptWithAttachments {
    if (!hasAttachments) return text;
    final buffer = StringBuffer(text);
    for (final att in attachments) {
      buffer.write(att.promptFragment);
    }
    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a copy of the message with updated fields.
  /// Essential for updating the UI when the AI is streaming
  /// or when attachments are added.
  ChatMessage copyWith({
    String? id,
    String? text,
    List<Attachment>? attachments,
    bool? isStreaming,
    String? modelName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      isUser: isUser,
      modelName: modelName ?? this.modelName,
      attachments: attachments ?? this.attachments,
      isStreaming: isStreaming ?? this.isStreaming,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Returns a copy with attachments replaced by the given list.
  ChatMessage withAttachments(List<Attachment> newAttachments) {
    return copyWith(attachments: newAttachments);
  }

  /// Returns a copy with a single attachment added.
  ChatMessage addAttachment(Attachment attachment) {
    return copyWith(attachments: [...attachments, attachment]);
  }

  /// Returns a copy with a specific attachment removed.
  ChatMessage removeAttachment(int index) {
    if (index < 0 || index >= attachments.length) return this;
    final newList = List<Attachment>.from(attachments);
    newList.removeAt(index);
    return copyWith(attachments: newList);
  }

  /// Returns a copy with a specific attachment updated (by index).
  ChatMessage updateAttachment(int index, Attachment updated) {
    if (index < 0 || index >= attachments.length) return this;
    final newList = List<Attachment>.from(attachments);
    newList[index] = updated;
    return copyWith(attachments: newList);
  }

  /// Equality based on key identifying fields.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.conversationId == conversationId &&
        other.senderId == senderId &&
        other.createdAt == createdAt &&
        other.text == text &&
        other.isUser == isUser;
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    senderId,
    createdAt,
    text,
    isUser,
  );

  @override
  String toString() {
    return 'ChatMessage(id: $id, role: ${isUser ? 'user' : 'agent'}, '
        'text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, '
        'attachments: ${attachments.length})';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════

extension ChatMessageListX on List<ChatMessage> {
  /// Get only user messages
  List<ChatMessage> get userMessages => where((m) => m.isUser).toList();

  /// Get only AI messages
  List<ChatMessage> get agentMessages => where((m) => !m.isUser).toList();

  /// Get only error messages
  List<ChatMessage> get errorMessages =>
      where((m) => m.isError).toList();

  /// Get the last message (or null if empty)
  ChatMessage? get lastOrNull => isEmpty ? null : last;

  /// Get the first message (or null if empty)
  ChatMessage? get firstOrNull => isEmpty ? null : first;

  /// Total character count of all messages
  int get totalCharacters =>
      fold(0, (sum, m) => sum + m.text.length);

  /// Total attachments across all messages
  int get totalAttachments =>
      fold(0, (sum, m) => sum + m.attachments.length);
}
