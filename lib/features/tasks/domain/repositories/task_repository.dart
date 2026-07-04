import '../models/quick_task.dart';

abstract class TaskRepository {
  Stream<List<QuickTask>> streamTasks(String ngoId, {String? status, String? priority});
  Future<void> createTask(QuickTask task);
  Future<void> updateTask(QuickTask task);
  Future<void> updateTaskStatus(String taskId, String status);
  Future<void> deleteTask(String taskId);
  Future<void> seedDemoTasksIfNeeded(String ngoId, String ngoName);
}
