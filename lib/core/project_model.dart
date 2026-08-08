// lib/core/project_model.dart


class ProjectFileContext {
  final String id;
  final String title;
  final String content;
  final bool isTextContext; // true if added manually via text context modal
  final String? filePath;
  final DateTime addedAt;

  ProjectFileContext({
    required this.id,
    required this.title,
    required this.content,
    this.isTextContext = true,
    this.filePath,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'isTextContext': isTextContext,
        'filePath': filePath,
        'addedAt': addedAt.toIso8601String(),
      };

  factory ProjectFileContext.fromJson(Map<String, dynamic> json) =>
      ProjectFileContext(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        isTextContext: json['isTextContext'] ?? true,
        filePath: json['filePath'],
        addedAt: json['addedAt'] != null
            ? DateTime.tryParse(json['addedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String instructions;
  final List<ProjectFileContext> files;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isStarred;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    this.instructions = '',
    this.files = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isStarred = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ProjectModel copyWith({
    String? name,
    String? description,
    String? instructions,
    List<ProjectFileContext>? files,
    DateTime? updatedAt,
    bool? isStarred,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      files: files ?? this.files,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isStarred: isStarred ?? this.isStarred,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'instructions': instructions,
        'files': files.map((f) => f.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isStarred': isStarred,
      };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Untitled Project',
        description: json['description'] ?? '',
        instructions: json['instructions'] ?? '',
        files: (json['files'] as List<dynamic>?)
                ?.map((e) => ProjectFileContext.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
            : DateTime.now(),
        isStarred: json['isStarred'] ?? false,
      );
}
