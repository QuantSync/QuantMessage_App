// lib/providers/project_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/project_model.dart';

const _uuid = Uuid();

class ProjectNotifier extends StateNotifier<List<ProjectModel>> {
  ProjectNotifier() : super([]) {
    _initDefaultProjects();
  }

  void _initDefaultProjects() {
    // Initial sample project if list is empty
    state = [
      ProjectModel(
        id: _uuid.v4(),
        name: 'Anubhav Singh Rajput',
        description: 'QuantSync AI Agent Integration & Architecture Optimization',
        instructions: 'Focus on high precision, clean Dart code, and responsive UI.',
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  ProjectModel createProject({
    required String name,
    required String description,
  }) {
    final newProj = ProjectModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = [newProj, ...state];
    _syncToSupabase(newProj);
    return newProj;
  }

  void updateProjectDetails({
    required String id,
    required String name,
    required String description,
  }) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(
            name: name,
            description: description,
            updatedAt: DateTime.now(),
          )
        else
          p
    ];
  }

  void updateInstructions(String id, String instructions) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(
            instructions: instructions,
            updatedAt: DateTime.now(),
          )
        else
          p
    ];
  }

  void addFileContext(String id, ProjectFileContext fileContext) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(
            files: [...p.files, fileContext],
            updatedAt: DateTime.now(),
          )
        else
          p
    ];
  }

  void toggleStar(String id) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(isStarred: !p.isStarred)
        else
          p
    ];
  }

  void deleteProject(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> _syncToSupabase(ProjectModel project) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      await supabase.from('projects').upsert({
        'id': project.id,
        'user_id': user.id,
        'name': project.name,
        'description': project.description,
        'instructions': project.instructions,
        'updated_at': project.updatedAt.toIso8601String(),
      });
    } catch (_) {
      // Graceful fallback for offline / local-only persistence
    }
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectNotifier, List<ProjectModel>>((ref) {
  return ProjectNotifier();
});

final activeProjectProvider = StateProvider<ProjectModel?>((ref) => null);
