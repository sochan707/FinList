
import 'package:flutter_test/flutter_test.dart';
import '../lib/service/goal_service.dart';
import '../lib/model/task.dart';
import '../lib/model/dateOnly.dart';

void main() {
  test('Create a goal with no space', () {
    final service = GoalService();

    service.createGoal(id: '01', title: 'Project slide ');

    expect(service.goals.length, 1);
    expect(service.goals.first.title, 'Project slide');
    expect(service.goals.first.description, null);
  });

  test('cannot create an existing goal', (){
    final service = GoalService();

    service.createGoal(id: '01', title: 'Project Slide');
    expect(
      () => service.createGoal(id: '01', title: 'Test flutter'),
      throwsException,
    );
  });

    test('Can edit an existing goal', () {
      final service = GoalService();

      service.createGoal(id: '01', title: 'Old project');

      service.editGoal(id: '01', title: 'Mobile project', description: 'Complete milestone 2',);

      expect(service.goals.length, 1);
      expect(service.goals.first.title, 'Mobile project');
      expect(service.goals.first.description,'Complete milestone 2',);
    });
  
  
  test('Cannot edit a goal that does not exist', () {
    final service = GoalService();

    expect(
      () => service.editGoal(id: '01',title: 'Mobile project',),
        throwsException,
      );
    });
  
  test('Can search goals by title', () {
      final service = GoalService();

      service.createGoal(id: '01', title: 'Flutter project');
      service.createGoal(id: '02', title: 'Study English');

      final result = service.searchGoals('flutter');

      expect(result.length, 1);
      expect(result.first.id, '01');
    });


    test('Can delete an existing goal', () {
      final service = GoalService();

      service.createGoal(id: '01', title: 'Flutter project');
      service.deleteGoal('01');

      expect(service.goals.length, 0);
    });

    test('Cannot delete a goal that does not exist', () {
      final service = GoalService();

      expect(
        () => service.deleteGoal('01'),
        throwsException,
      );
    });


    test('Can link an existing task to a goal', () {
      final tasks = [Task(id: 'T01',title: 'Finish homework',workDay: DateOnly(day: 19, month: 11, year: 2026),)];

      final service = GoalService(tasks: tasks);
      service.createGoal(id: 'G01', title: 'Study');

      service.linkTask(taskId: 'T01', goalId: 'G01');

      expect(tasks.first.goalId, 'G01');
      expect(tasks.first.goalOrder, 0);
    });


      test('Cannot link task to a missing goal', () {
        final tasks = [Task(id: 'T01',title: 'Finish homework', workDay: DateOnly(day: 19, month: 11, year: 2026),),];

        final service = GoalService(tasks: tasks);

        expect(
          () => service.linkTask(taskId: 'T01', goalId: 'G01'),
          throwsException,
          );
      });

      test('Can get tasks for a goal', () {
        final tasks = [
          Task(id: 'T01', title: 'Task 1',workDay: DateOnly(day: 19, month: 11, year: 2026),goalId: 'G01',goalOrder: 0,),
          Task(id: 'T02', title: 'Task 2', workDay: DateOnly(day: 19, month: 11, year: 2026),goalId: 'G02', goalOrder: 0, ),
          ];

        final service = GoalService(tasks: tasks);
        final result = service.getTasksForGoal('G01');

        expect(result.length, 1);
        expect(result.first.id, 'T01');
    });

    test('Can get the next unfinished task', () {
      final tasks = [
      Task(id: 'T01',title: 'Task 1',workDay: DateOnly(day: 19, month: 11, year: 2026),isCompleted: true,goalId: 'G01', goalOrder: 0 ),
      Task(id: 'T02',title: 'Task 2',workDay: DateOnly(day: 19, month: 11, year: 2026),goalId: 'G01',goalOrder: 1,),
    ];

      final service = GoalService(tasks: tasks);

      final result = service.getUpNext('G01');

      expect(result?.id, 'T02');
    });

    test('Can calculate goal progress', () {
  final tasks = [
    Task( id: 'T01', title: 'Task 1', workDay: DateOnly(day: 19, month: 11, year: 2026),isCompleted: true, goalId: 'G01',goalOrder: 0, ),
    Task(id: 'T02', title: 'Task 2', workDay: DateOnly(day: 19, month: 11, year: 2026),goalId: 'G01',goalOrder: 1,),
  ];

    final service = GoalService(tasks: tasks);

    final result = service.getGoalProgress('G01');

    expect(result?.completedTasks, 1);
    expect(result?.totalTasks, 2);
    expect(result?.percentage, 50);
    expect(result?.isComplete, false);
  });

  test('Returns null progress when goal has no tasks', () {
    final service = GoalService();

    service.createGoal(id: 'G01', title: 'Study');

    expect(service.getGoalProgress('G01'), null);
  });

  test('Cannot delete a goal that still has linked tasks', () {
  final tasks = [
    Task(id: 'T01', title: 'Task 1', workDay: DateOnly(day: 19, month: 11, year: 2026), goalId: 'G01', goalOrder: 0),
  ];
  final service = GoalService(tasks: tasks);
  service.createGoal(id: 'G01', title: 'Study');

  expect(() => service.deleteGoal('G01'), throwsStateError);
  expect(service.goals.length, 1);
});

test('Delete a goal keeps chosen tasks and deletes the others', () {
  final tasks = [
    Task(id: 'T01', title: 'Task 1', workDay: DateOnly(day: 19, month: 11, year: 2026), goalId: 'G01', goalOrder: 0),
    Task(id: 'T02', title: 'Task 2', workDay: DateOnly(day: 19, month: 11, year: 2026), goalId: 'G01', goalOrder: 1),
  ];
  final service = GoalService(tasks: tasks);
  service.createGoal(id: 'G01', title: 'Study');

  final choices = service.createDeletionChoices('G01');
  expect(choices.taskIdsToKeep, {'T01', 'T02'}); // All start checked.

  choices.taskIdsToKeep.remove('T02');
  service.confirmDeleteGoal(choices);

  expect(service.goals.length, 0);
  expect(tasks.length, 1);
  expect(tasks.first.id, 'T01');
  expect(tasks.first.goalId, null);
  expect(tasks.first.goalOrder, null);
});

test('Old deletion choices are rejected when the goal tasks changed', () {
  final tasks = [
    Task(id: 'T01', title: 'Task 1', workDay: DateOnly(day: 19, month: 11, year: 2026), goalId: 'G01', goalOrder: 0),
    Task(id: 'T02', title: 'Task 2', workDay: DateOnly(day: 19, month: 11, year: 2026)),
  ];
  final service = GoalService(tasks: tasks);
  service.createGoal(id: 'G01', title: 'Study');

  final choices = service.createDeletionChoices('G01');
  service.linkTask(taskId: 'T02', goalId: 'G01');

  expect(() => service.confirmDeleteGoal(choices), throwsStateError);
  expect(service.goals.length, 1);
  expect(tasks.length, 2);
});

test('If saving fails when deleting a goal, nothing changes', () {
  final tasks = [
    Task(id: 'T01', title: 'Task 1', workDay: DateOnly(day: 19, month: 11, year: 2026), goalId: 'G01', goalOrder: 0),
  ];
  bool shouldFail = false;

  final service = GoalService(
    tasks: tasks,
    saveChanges: (newGoals, newTasks) {
      if (shouldFail) throw Exception('Disk error');
    },
  );
  service.createGoal(id: 'G01', title: 'Study');

  final choices = service.createDeletionChoices('G01');
  choices.taskIdsToKeep.clear(); // Delete the task too.
  shouldFail = true;

  expect(() => service.confirmDeleteGoal(choices), throwsException);
  expect(service.goals.length, 1);
  expect(tasks.length, 1);
  expect(tasks.first.goalId, 'G01');
});

test('Linking a task to a different goal moves it', () {
  final tasks = [
    Task(id: 'T01', title: 'Task 1', workDay: DateOnly(day: 19, month: 11, year: 2026), goalId: 'G01', goalOrder: 0),
  ];
  final service = GoalService(tasks: tasks);
  service.createGoal(id: 'G01', title: 'Study');
  service.createGoal(id: 'G02', title: 'Work');

  service.linkTask(taskId: 'T01', goalId: 'G02');

  expect(tasks.length, 1);
  expect(tasks.first.goalId, 'G02');
  expect(tasks.first.goalOrder, 0);
  expect(service.getTasksForGoal('G01').length, 0);
});
}

