import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../data/mock_data.dart';
import '../repositories/cilalu_repository.dart';

/// Dedicated controller for Task management, subtasks, progress updates, and review approvals.
class TaskController extends ChangeNotifier {
  final CilaluRepository _repository;

  List<Task> _tasks = List.from(kInitialTasks);
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  final void Function(Task task)? onTaskCreated;
  final void Function(Task task, int progressPercent)? onTaskProgressUpdated;
  final void Function(Task task)? onTaskApproved;

  TaskController({
    CilaluRepository? repository,
    this.onTaskCreated,
    this.onTaskProgressUpdated,
    this.onTaskApproved,
    List<Task>? initialTasks,
  }) : _repository = repository ?? CilaluRepository() {
    if (initialTasks != null) {
      _tasks = List.from(initialTasks);
    }
  }

  List<Task> get tasks => List.unmodifiable(_tasks);
  int get activeReviewCount => _tasks.where((t) => t.needsReview).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void setTasks(List<Task> tasks) {
    _tasks = List.from(tasks);
    notifyListeners();
  }

  void clear() {
    _tasks = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadTasks(String companyCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.getTasks(companyCode);
      if (loaded.isNotEmpty || companyCode != 'CILALU-88') {
        _tasks = loaded;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('TaskController.loadTasks error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask(String companyCode, Task newTask) async {
    _tasks = [newTask, ..._tasks];
    notifyListeners();

    onTaskCreated?.call(newTask);

    try {
      await _repository.createTask(companyCode, newTask);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('TaskController.createTask repository error: $e');
    }
  }

  Future<void> deleteTask(String companyCode, String taskId) async {
    _tasks = _tasks.where((t) => t.id != taskId).toList();
    notifyListeners();

    try {
      await _repository.deleteTask(companyCode, taskId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('TaskController.deleteTask repository error: $e');
    }
  }

  Future<Task?> saveProgress(
    String companyCode,
    String taskId,
    List<Subtask> updatedSubtasks,
    int progressPercent,
  ) async {
    Task? target;
    _tasks = _tasks.map((t) {
      if (t.id == taskId) {
        final isDone = progressPercent == 100;
        target = t.copyWith(
          subtasks: updatedSubtasks,
          progressPercent: progressPercent,
          status: isDone ? TaskStatus.completed : TaskStatus.inProgress,
          needsReview: isDone ? true : t.needsReview,
        );
        return target!;
      }
      return t;
    }).toList();

    if (target != null) {
      notifyListeners();
      onTaskProgressUpdated?.call(target!, progressPercent);

      try {
        await _repository.updateTask(companyCode, target!);
      } catch (e) {
        _errorMessage = e.toString();
        debugPrint('TaskController.saveProgress repository error: $e');
      }
    }
    return target;
  }

  Future<Task?> approveTask(String companyCode, String taskId) async {
    Task? target;
    _tasks = _tasks.map((t) {
      if (t.id == taskId) {
        target = t.copyWith(
          status: TaskStatus.completed,
          progressPercent: 100,
          subtasks: t.subtasks
              .map((st) => st.copyWith(completed: true))
              .toList(),
          needsReview: false,
        );
        return target!;
      }
      return t;
    }).toList();

    if (target != null) {
      notifyListeners();
      onTaskApproved?.call(target!);

      try {
        await _repository.updateTask(companyCode, target!);
      } catch (e) {
        _errorMessage = e.toString();
        debugPrint('TaskController.approveTask repository error: $e');
      }
    }
    return target;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
