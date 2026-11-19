
import '../model/goal.dart';
import '../model/task.dart';

class GoalProgress {
  final int completedTasks;
  final int totalTasks;
  final double percentage;
  final bool isComplete;
  final Task? nextTask;

  GoalProgress({
    required this.completedTasks,required this.totalTasks,required this.percentage,required this.isComplete,required this.nextTask,});
}

class GoalDeletionChoices {
  final String goalId;
  final Set<String> taskIds;
  final Set<String> taskIdsToKeep;

  GoalDeletionChoices({required this.goalId, required Set<String> taskIds, required Set<String> taskIdsToKeep,})  
      : taskIds = Set<String>.from(taskIds),
        taskIdsToKeep = Set<String>.from(taskIdsToKeep);
}

class GoalService {
  final List<Goal> goals = [];
  final List<Task> tasks;

 
  // If it throws an error, the current lists remain unchanged.
  final void Function(List<Goal>, List<Task>)? saveChanges;

  GoalService({
    List<Task>? tasks,
    this.saveChanges,
  }) : tasks = tasks ?? [];

    // Create goal
  void createGoal({ required String id,required String title,String? description,}) {
    if (_findGoalOrNull(id) != null) {
      throw Exception('Goal $id already exists');
    }

    final newGoals = goals.toList();
    newGoals.add(Goal(id: id, title: title.trim(), description: description));

    _save(newGoals, tasks.toList());
  }

  // Edit goal
  void editGoal({ required String id, required String title, String? description,}) {
    for (int i = 0; i < goals.length; i++) {
      if (goals[i].id == id) {
        final newGoals = goals.toList();
        newGoals[i] = Goal(id: id, title: title.trim(), description: description);

        _save(newGoals, tasks.toList());
        return;
      }
    }

    throw Exception('Goal $id not found');
  }

  // Search goal
  List<Goal> searchGoals(String query) {
    final text = query.trim().toLowerCase();

    if (text.isEmpty) return goals;

    final result = <Goal>[];

    for (Goal goal in goals) {
      final title = goal.title.toLowerCase();
      final description = (goal.description ?? '').toLowerCase();

      if (title.contains(text) || description.contains(text)) {
        result.add(goal);
      }
    }

    return result;
  }

  void deleteGoal(String id) {
    final goal = _findGoalOrNull(id);

    if (goal == null) {
      throw Exception('Goal $id not found');
    }

    if (_tasksForGoal(id).isNotEmpty) {
      throw StateError('Goal has linked tasks. Use confirmDeleteGoal.');
    }

    goals.remove(goal);
  }
  // Link an existing task to a goal.
  void linkTask({ required String taskId, required String goalId,}) {
    if (_findGoalOrNull(goalId) == null) {
      throw Exception('Goal $goalId not found');
    }

    final taskIndex = _findTaskIndex(taskId);
    if (taskIndex == -1) {
      throw Exception('Task $taskId not found');
    }

    final task = tasks[taskIndex];

    if (task.goalId == goalId) return;

    final newOrder = _tasksForGoal(goalId).length;

    tasks[taskIndex] = _copyTask(task,goalId: goalId,goalOrder: newOrder,);

    // Re-number the previous goal after moving the task away.
    if (task.goalId != null) {
      _updateTaskOrder(task.goalId!);
    }
  }

  // Return tasks in their saved goal order.
  List<Task> getTasksForGoal(String goalId) {
    final result = _tasksForGoal(goalId);
    result.sort((a, b) =>
        (a.goalOrder ?? 0).compareTo(b.goalOrder ?? 0));
    return result;
  }

  // Move a task to a different position in its goal.
  void changeTaskOrder({required String taskId,  required int newOrder,}) {
    final taskIndex = _findTaskIndex(taskId);
    if (taskIndex == -1) {
      throw Exception('Task $taskId not found');
    }

    final task = tasks[taskIndex];
    final goalId = task.goalId;

    if (goalId == null) {
      throw Exception('Task $taskId is not linked to a goal');
    }

    final goalTasks = getTasksForGoal(goalId);

    if (newOrder < 0 || newOrder >= goalTasks.length) {
      throw ArgumentError('Invalid task order');
    }

    goalTasks.removeWhere((t) => t.id == taskId);
    goalTasks.insert(newOrder, task);

    for (int i = 0; i < goalTasks.length; i++) {
      final index = _findTaskIndex(goalTasks[i].id);
      tasks[index] = _copyTask(
        goalTasks[i],
        goalId: goalId,
        goalOrder: i,
      );
    }
  }

  // First unfinished task in the saved order.
  Task? getUpNext(String goalId) {
    for (Task task in getTasksForGoal(goalId)) {
      if (!task.isCompleted) return task;
    }

    return null;
  }

  // Return null when the goal has no linked tasks.
  GoalProgress? getGoalProgress(String goalId) {
    final goalTasks = getTasksForGoal(goalId);

    if (goalTasks.isEmpty) return null;

    int completed = 0;

    for (Task task in goalTasks) {
      if (task.isCompleted) completed++;
    }

    return GoalProgress(
      completedTasks: completed,
      totalTasks: goalTasks.length,
      percentage: completed / goalTasks.length * 100,
      isComplete: completed == goalTasks.length,
      nextTask: getUpNext(goalId),
    );
  }

  // Prepare deletion choices.
  // By default, every linked task is selected to be kept.
  GoalDeletionChoices createDeletionChoices(String goalId) {
    if (_findGoalOrNull(goalId) == null) {
      throw Exception('Goal $goalId not found');
    }

    final linkedTasks = _tasksForGoal(goalId);
    final taskIds = linkedTasks.map((task) => task.id).toSet();

    return GoalDeletionChoices(goalId: goalId,  taskIds: taskIds,  taskIdsToKeep: taskIds,);
  }


  // Tasks not selected to keep are deleted.
  void confirmDeleteGoal(GoalDeletionChoices choices) {
  if (_findGoalOrNull(choices.goalId) == null) {
    throw Exception('Goal ${choices.goalId} not found');
  }

  final currentTaskIds =
      _tasksForGoal(choices.goalId).map((task) => task.id).toSet();

  // Reject choices if the goal's linked tasks changed.
  if (!_sameSet(currentTaskIds, choices.taskIds)) {
    throw StateError('Goal tasks changed. Refresh the deletion choices.');
  }

  if (!choices.taskIds.containsAll(choices.taskIdsToKeep)) {
    throw ArgumentError('Invalid task selection');
  }

  final newGoals = <Goal>[];
  for (final goal in goals) {
    if (goal.id != choices.goalId) {
      newGoals.add(goal);
    }
  }

  final newTasks = <Task>[];
  for (final task in tasks) {
    if (task.goalId != choices.goalId) {
      newTasks.add(task);
    } else if (choices.taskIdsToKeep.contains(task.id)) {
      // Kept tasks lose their goal link and goal order.
      newTasks.add(_copyTask(task, goalId: null, goalOrder: null));
    }
    // Other tasks of this goal are not added, so they are deleted.
  }

  // Goal and tasks are saved together.
  _save(newGoals, newTasks);
}


  // Find goal
  Goal? _findGoalOrNull(String id) {
    for (Goal goal in goals) {
      if (goal.id == id) return goal;
    }

    return null;
  }

  int _findTaskIndex(String id) {
    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].id == id) return i;
    }

    return -1;
  }

  List<Task> _tasksForGoal(String goalId) {
    return tasks.where((task) => task.goalId == goalId).toList();
  }


  void _updateTaskOrder(String goalId) {
    final goalTasks = getTasksForGoal(goalId);

    for (int i = 0; i < goalTasks.length; i++) {
      final index = _findTaskIndex(goalTasks[i].id);

      tasks[index] = _copyTask( goalTasks[i],goalId: goalId,goalOrder: i,);
    }
  }

  bool _sameSet(Set<String> first, Set<String> second) {
    return first.length == second.length && first.containsAll(second);
  }
  // Save first. If saving fails, the real lists are not touched.
  void _save(List<Goal> newGoals, List<Task> newTasks) {
    final save = saveChanges;
    if (save != null) {
      save(newGoals, newTasks);
    }

    goals.clear();
    goals.addAll(newGoals);

    tasks.clear();
    tasks.addAll(newTasks);
  }

  Task _copyTask(Task task, {String? goalId, int? goalOrder,}) {
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
      groupId: task.groupId,
      goalId: goalId,
      goalOrder: goalOrder,
      priority: task.priority,
    );
  }
}
