import 'package:flutter/material.dart';
import '../../domain/models/quick_task.dart';
import '../../domain/repositories/task_repository.dart';

class TaskController extends ChangeNotifier {
  final TaskRepository _repository;

  bool _isLoading = false;
  String? _error;

  TaskController(this._repository);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<QuickTask>> streamTasks(String ngoId, {String? status, String? priority}) {
    return _repository.streamTasks(ngoId, status: status, priority: priority);
  }

  Future<void> seedDemoTasksIfNeeded(String ngoId, String ngoName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.seedDemoTasksIfNeeded(ngoId, ngoName);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required String priority,
    required String category,
    required String assignedTo,
    DateTime? dueDate,
    required String ngoId,
    required String ngoName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = QuickTask(
        id: '',
        title: title,
        description: description,
        priority: priority,
        category: category,
        assignedTo: assignedTo,
        status: 'pending',
        dueDate: dueDate,
        ngoId: ngoId,
        ngoName: ngoName,
        createdAt: DateTime.now(),
      );
      await _repository.createTask(task);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask({
    required String id,
    required String title,
    required String description,
    required String priority,
    required String category,
    required String assignedTo,
    DateTime? dueDate,
    required String status,
    required String ngoId,
    required String ngoName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = QuickTask(
        id: id,
        title: title,
        description: description,
        priority: priority,
        category: category,
        assignedTo: assignedTo,
        status: status,
        dueDate: dueDate,
        ngoId: ngoId,
        ngoName: ngoName,
        createdAt: DateTime.now(), // Ignored in update
      );
      await _repository.updateTask(task);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateTaskStatus(taskId, newStatus);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteTask(taskId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
