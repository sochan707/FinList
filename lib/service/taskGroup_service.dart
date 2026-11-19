import '../model/taskGroup.dart';
import '../model/task.dart';

class TaskGroupService {
  final List<TaskGroup> groups;
  final List<Task> tasks;

  // If it throws an error, the current lists remain unchanged.
  final void Function(List<TaskGroup>, List<Task>)? saveChanges;

  TaskGroupService({
    List<TaskGroup>? groups,
    List<Task>? tasks,
    this.saveChanges,
  })  : groups = groups ?? [],
        tasks = tasks ?? [];

  // Create group
  void createGroup({ required String id,  required String name,}) {
    if (_findGroupIndex(id) != -1) {
      throw Exception('Group $id already exists');
    }

    final newGroups = List<TaskGroup>.from(groups);
    newGroups.add(TaskGroup(id: id, name: name.trim()));

    _save(newGroups, List<Task>.from(tasks));
  }

  // Rename group
  void renameGroup({required String id,required String name,}) {
    final index = _findGroupIndex(id);
    if (index == -1) {
      throw Exception('Group $id not found');
    }

    final newGroups = List<TaskGroup>.from(groups);
    newGroups[index] = TaskGroup(id: id, name: name.trim());

    _save(newGroups, List<Task>.from(tasks));
  }

  // Put a task in one existing group.
  void assignTaskToGroup({ required String taskId,String? groupId,}) {
    final taskIndex = _findTaskIndex(taskId);
    if (taskIndex == -1) {
      throw Exception('Task $taskId not found');
    }

    if (groupId != null && _findGroupIndex(groupId) == -1) {
      throw Exception('Group $groupId not found');
    }

    final newTasks = List<Task>.from(tasks);
    newTasks[taskIndex] = _copyTask(tasks[taskIndex], groupId);

    _save(List<TaskGroup>.from(groups), newTasks);
  }

  // Delete group.
  void deleteGroup(String id) {
    final index = _findGroupIndex(id);
    if (index == -1) {
      throw Exception('Group $id not found');
    }

    final newGroups = List<TaskGroup>.from(groups);
    newGroups.removeAt(index);

    final newTasks = <Task>[];
    for (final task in tasks) {
      if (task.groupId == id) {
        newTasks.add(_copyTask(task, null));
      } else {
        newTasks.add(task);
      }
    }

    // Groups and tasks are saved together.
    _save(newGroups, newTasks);
  }

  int _findGroupIndex(String id) {
    for (int i = 0; i < groups.length; i++) {
      if (groups[i].id == id) return i;
    }

    return -1;
  }

  int _findTaskIndex(String id) {
    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].id == id) return i;
    }

    return -1;
  }

  // Save first. 
  void _save(List<TaskGroup> newGroups, List<Task> newTasks) {
    final save = saveChanges;
    if (save != null) {
      save(newGroups, newTasks);
    }

    groups.clear();
    groups.addAll(newGroups);

    tasks.clear();
    tasks.addAll(newTasks);
  }

  // Same task with a new group. A null groupId means "no group".
  Task _copyTask(Task task, String? groupId) {
    return Task(
      id: task.id,
      title: task.title,
      workDay: task.workDay,
      isCompleted: task.isCompleted,
      isTopPriority: task.isTopPriority,
      rewardGranted: task.rewardGranted,
      subTasks: task.subTasks,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      plannedTime: task.plannedTime,
      reminderAt: task.reminderAt,
      notes: task.notes,
      groupId: groupId,
      goalId: task.goalId,
      goalOrder: task.goalOrder,
      priority: task.priority,
    );
  }
}