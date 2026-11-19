import 'package:flutter/material.dart';
import '../model/dateOnly.dart';
import '../model/subTask.dart';
import '../model/task.dart';



class TaskMoveChoices {
  final String taskId;
  final DateOnly newWorkDay;
  final Set<String> markedTaskIds;

  TaskMoveChoices({required this.taskId, required this.newWorkDay,required this.markedTaskIds});
}

class TaskService {
  static const int maxTopTasksPerDay = 3;

  // Pass the SAME list to GoalService so both services see the same tasks.
  final List<Task> tasks;

  // If it throws an error, the current list remains unchanged.
  final void Function(List<Task>)? saveChanges;

  TaskService({
    List<Task>? tasks,
    this.saveChanges,
  }) : tasks = tasks ?? [];

  // Add task. New tasks start unfinished, not marked, no reward, no priority.
  void addTask({ required String id, required String title, required DateOnly workDay, DateOnly? dueDate, TimeOfDay? dueTime, TimeOfDay? plannedTime,  DateTime? reminderAt, String? notes,}) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Task ID cannot be empty');
    }
    if (_findTaskIndex(id) != -1) {
      throw Exception('Task $id already exists');
    }

    final cleanTitle = _cleanTitle(title);
    _checkDueTime(dueDate, dueTime);

    final newTasks = List<Task>.from(tasks);
    newTasks.add(Task( id: id,  title: cleanTitle,  workDay: workDay, dueDate: dueDate, dueTime: dueTime, plannedTime: plannedTime, reminderAt: reminderAt, notes: notes,), );
    _saveTasks(newTasks);
  }

  Task? getTask(String id) {
    final index = _findTaskIndex(id);
    if (index == -1) return null;
    return tasks[index];
  }

// edit task
  void editTask({ required String id, required String title, DateOnly? dueDate, TimeOfDay? dueTime, TimeOfDay? plannedTime,  DateTime? reminderAt, String? notes,TaskPriority? priority,}) {
    final task = _getTaskOrThrow(id);
    final cleanTitle = _cleanTitle(title);
    _checkDueTime(dueDate, dueTime);

    _replaceTask(
      _withDetails( task, title: cleanTitle, dueDate: dueDate, dueTime: dueTime,  plannedTime: plannedTime,reminderAt: reminderAt,  notes: notes,priority: priority, ),
    );
  }

  // Removing a due date also clears its due time.
  void clearDueDate(String id) {
    final task = _getTaskOrThrow(id);

    _replaceTask(
      _withDetails(task, title: task.title, dueDate: null, dueTime: null, plannedTime: task.plannedTime,reminderAt: task.reminderAt, notes: task.notes, priority: task.priority, ),
    );
  }

  // Delete the task
  void deleteTask(String id) {
    final task = _getTaskOrThrow(id);

    final newTasks = List<Task>.from(tasks);
    newTasks.removeAt(_indexIn(newTasks, id));

    // Close the gap in the goal's order.
    final goalId = task.goalId;
    if (goalId != null) {
      _renumberGoal(newTasks, goalId);
    }

    _saveTasks(newTasks);
  }

  // Complete the task. 
  void completeTask(String id) {
    final task = _getTaskOrThrow(id);
    if (task.isCompleted) return;

    _replaceTask(_copyTask(task, isCompleted: true));
  }

  // Reopen the task. rewardGranted is never reset.
  void reopenTask(String id) {
    final task = _getTaskOrThrow(id);
    if (!task.isCompleted) return;

    _replaceTask(_copyTask(task, isCompleted: false));
  }

  // Mark or unmark a task. At most three marked tasks per work day.
  void setTopPriority({required String taskId, required bool isTopPriority}) {
    final task = _getTaskOrThrow(taskId);
    if (task.isTopPriority == isTopPriority) return;

    if (isTopPriority) {
      final marked = _markedTasksOnDay(task.workDay, exceptTaskId: taskId);
      if (marked.length >= maxTopTasksPerDay) {
        throw StateError('This day already has $maxTopTasksPerDay marked tasks');
      }
    }

    _replaceTask(_copyTask(task, isTopPriority: isTopPriority));
  }


  TaskMoveChoices? getMoveChoices({ required String taskId, required DateOnly newWorkDay,}) {
    final task = _getTaskOrThrow(taskId);

    if (!task.isTopPriority) return null;
    if (task.workDay.isSameDay(newWorkDay)) return null;

    final marked = _markedTasksOnDay(newWorkDay, exceptTaskId: taskId);
    if (marked.length < maxTopTasksPerDay) return null;

    return TaskMoveChoices( taskId: taskId, newWorkDay: newWorkDay, markedTaskIds: marked.map((t) => t.id).toSet(),);
  }

  // Move an unfinished task to another work day.
  void moveTask({required String taskId, required DateOnly newWorkDay}) {
    final task = _getTaskOrThrow(taskId);

    if (task.isCompleted) {
      throw StateError('A completed task cannot be moved');
    }
    if (task.workDay.isSameDay(newWorkDay)) return;

    // A marked task needs a free spot. Use getMoveChoices first.
    if (task.isTopPriority) {
      final marked = _markedTasksOnDay(newWorkDay, exceptTaskId: taskId);
      if (marked.length >= maxTopTasksPerDay) {
        throw StateError('The new day is full. Choose a marked task to replace.');
      }
    }

    _replaceTask(_movedTask(task, newWorkDay));
  }

  // Move a marked task to a full day. The chosen task loses its mark.
  void moveTaskWithReplacement({required TaskMoveChoices choices, required String replaceTaskId,}) {
    final task = _getTaskOrThrow(choices.taskId);

    if (task.isCompleted) {
      throw StateError('A completed task cannot be moved');
    }
    if (!choices.markedTaskIds.contains(replaceTaskId)) {
      throw ArgumentError('Choose one of the marked tasks');
    }

    // Check again when saving.
    final currentIds = _markedTasksOnDay(choices.newWorkDay,exceptTaskId: task.id,).map((t) => t.id).toSet();

    if (!task.isTopPriority || !_sameSet(currentIds, choices.markedTaskIds)) {
      throw StateError('Marked tasks changed. Refresh the choices.');
    }

    final newTasks = List<Task>.from(tasks);

    newTasks[_indexIn(newTasks, task.id)] = _movedTask(task, choices.newWorkDay);

    final replacedIndex = _indexIn(newTasks, replaceTaskId);
    newTasks[replacedIndex] = _copyTask(
      newTasks[replacedIndex],
      isTopPriority: false,
    );

    _saveTasks(newTasks);
  }

  void addSubTask({ required String taskId, required String subTaskId, required String title,}) {
    final task = _getTaskOrThrow(taskId);
    final cleanTitle = _cleanTitle(title);

    for (final subTask in task.subTasks) {
      if (subTask.id == subTaskId) {
        throw Exception('Sub-task $subTaskId already exists');
      }
    }

    final subTasks = List<SubTask>.from(task.subTasks);
    subTasks.add(
      SubTask(id: subTaskId, title: cleanTitle, order: subTasks.length),
    );

    _replaceTask(_copyTask(task, subTasks: subTasks));
  }

  void editSubTask({ required String taskId, required String subTaskId, required String title,}) {
    final task = _getTaskOrThrow(taskId);
    final cleanTitle = _cleanTitle(title);
    final index = _subTaskIndex(task, subTaskId);

    final subTasks = List<SubTask>.from(task.subTasks);
    final old = subTasks[index];
    subTasks[index] = SubTask(id: old.id, title: cleanTitle, isCompleted: old.isCompleted, order: old.order,);

    _replaceTask(_copyTask(task, subTasks: subTasks));
  }

  // Checking a step never completes the parent task.
  void setSubTaskCompleted({ required String taskId, required String subTaskId, required bool isCompleted,}) {
    final task = _getTaskOrThrow(taskId);
    final index = _subTaskIndex(task, subTaskId);

    final subTasks = List<SubTask>.from(task.subTasks);
    final old = subTasks[index];
    subTasks[index] = SubTask( id: old.id, title: old.title, isCompleted: isCompleted, order: old.order,);

    _replaceTask(_copyTask(task, subTasks: subTasks));
  }

  void changeSubTaskOrder({ required String taskId, required String subTaskId,required int newOrder,}) {
    final task = _getTaskOrThrow(taskId);
    final index = _subTaskIndex(task, subTaskId);

    if (newOrder < 0 || newOrder >= task.subTasks.length) {
      throw ArgumentError('Invalid sub-task order');
    }

    final subTasks = List<SubTask>.from(task.subTasks);
    final moved = subTasks.removeAt(index);
    subTasks.insert(newOrder, moved);

    _replaceTask(_copyTask(task, subTasks: _renumberSubTasks(subTasks)));
  }

  void deleteSubTask({required String taskId, required String subTaskId}) {
    final task = _getTaskOrThrow(taskId);
    final index = _subTaskIndex(task, subTaskId);

    final subTasks = List<SubTask>.from(task.subTasks);
    subTasks.removeAt(index);

    _replaceTask(_copyTask(task, subTasks: _renumberSubTasks(subTasks)));
  }

  String _cleanTitle(String title) {
    final text = title.trim();
    if (text.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    return text;
  }

  // A due time needs a due date.
  void _checkDueTime(DateOnly? dueDate, TimeOfDay? dueTime) {
    if (dueTime != null && dueDate == null) {
      throw ArgumentError('A due time needs a due date');
    }
  }

  int _findTaskIndex(String id) {
    return _indexIn(tasks, id);
  }

  int _indexIn(List<Task> list, String id) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == id) return i;
    }
    return -1;
  }

  Task _getTaskOrThrow(String id) {
    final index = _findTaskIndex(id);
    if (index == -1) {
      throw Exception('Task $id not found');
    }
    return tasks[index];
  }

  int _subTaskIndex(Task task, String subTaskId) {
    for (int i = 0; i < task.subTasks.length; i++) {
      if (task.subTasks[i].id == subTaskId) return i;
    }
    throw Exception('Sub-task $subTaskId not found');
  }

  // Marked tasks on a day, including completed ones that keep the mark.
  List<Task> _markedTasksOnDay(DateOnly day, {String? exceptTaskId}) {
    final result = <Task>[];

    for (final task in tasks) {
      if (task.id == exceptTaskId) continue;
      if (task.isTopPriority && task.workDay.isSameDay(day)) {
        result.add(task);
      }
    }

    return result;
  }

  // Same task on a new work day, with the reminder shifted.
  Task _movedTask(Task task, DateOnly newDay) {
    final days = _daysBetween(task.workDay, newDay);
    final reminder = task.reminderAt;

    return _copyTask(
      task,
      workDay: newDay,
      reminderAt: reminder == null ? null : _shiftReminder(reminder, days),
    );
  }

  // Calendar days between two dates (negative when moving earlier).
  int _daysBetween(DateOnly from, DateOnly to) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    return end.difference(start).inDays;
  }

  // Move by calendar days and keep the same clock time.
  DateTime _shiftReminder(DateTime reminder, int days) {
    return DateTime( reminder.year,reminder.month,reminder.day + days,  reminder.hour, reminder.minute,reminder.second,);
  }

  List<SubTask> _renumberSubTasks(List<SubTask> subTasks) {
    final result = <SubTask>[];

    for (int i = 0; i < subTasks.length; i++) {
      final old = subTasks[i];
      result.add(
        SubTask( id: old.id, title: old.title,isCompleted: old.isCompleted, order: i, ),
      );
    }

    return result;
  }

  // Put goal order back to 0, 1, 2... in a list that is about to be saved.
  void _renumberGoal(List<Task> list, String goalId) {
    final goalTasks = <Task>[];

    for (final task in list) {
      if (task.goalId == goalId) goalTasks.add(task);
    }

    goalTasks.sort((a, b) => (a.goalOrder ?? 0).compareTo(b.goalOrder ?? 0));

    for (int i = 0; i < goalTasks.length; i++) {
      final index = _indexIn(list, goalTasks[i].id);
      list[index] = _copyTask(goalTasks[i], goalOrder: i);
    }
  }

  bool _sameSet(Set<String> first, Set<String> second) {
    return first.length == second.length && first.containsAll(second);
  }

  // Replace one task in the list and save.
  void _replaceTask(Task updated) {
    final newTasks = List<Task>.from(tasks);
    newTasks[_indexIn(newTasks, updated.id)] = updated;
    _saveTasks(newTasks);
  }

  // Save first. If saving fails, the real list is not touched.
  void _saveTasks(List<Task> newTasks) {
    final save = saveChanges;
    if (save != null) {
      save(newTasks);
    }

    tasks.clear();
    tasks.addAll(newTasks);
  }

  Task _copyTask(Task task, { DateOnly? workDay,  bool? isCompleted, bool? isTopPriority, List<SubTask>? subTasks, DateTime? reminderAt, int? goalOrder,
  }) {
    return Task(
      id: task.id,
      title: task.title,
      workDay: workDay ?? task.workDay,
      isCompleted: isCompleted ?? task.isCompleted,
      isTopPriority: isTopPriority ?? task.isTopPriority,
      rewardGranted: task.rewardGranted,
      subTasks: subTasks ?? task.subTasks,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      plannedTime: task.plannedTime,
      reminderAt: reminderAt ?? task.reminderAt,
      notes: task.notes,
      groupId: task.groupId,
      goalId: task.goalId,
      goalOrder: goalOrder ?? task.goalOrder,
      priority: task.priority,
    );
  }

  // Copy a task and replace its detail fields. Here null really clears.
  Task _withDetails(
    Task task, { required String title, required DateOnly? dueDate, required TimeOfDay? dueTime, required TimeOfDay? plannedTime, required DateTime? reminderAt, required String? notes,required TaskPriority? priority,}) {
    return Task(
      id: task.id,
      title: title,
      workDay: task.workDay,
      isCompleted: task.isCompleted,
      isTopPriority: task.isTopPriority,
      rewardGranted: task.rewardGranted,
      subTasks: task.subTasks,
      dueDate: dueDate,
      dueTime: dueTime,
      plannedTime: plannedTime,
      reminderAt: reminderAt,
      notes: notes,
      groupId: task.groupId,
      goalId: task.goalId,
      goalOrder: task.goalOrder,
      priority: priority,
    );
  }
}