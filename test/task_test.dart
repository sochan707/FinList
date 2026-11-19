import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/service/task_service.dart';
import '../lib/model/task.dart';
import '../lib/model/dateOnly.dart';

// November 2026: 16 = Monday, 17 = Tuesday, 18 = Wednesday, 19 = Thursday, 20 = Friday
void main() {
  test('Create a task with starting values', () {
    final service = TaskService();

    service.addTask(
      id: 'T01',
      title: ' Homework ',
      workDay: DateOnly(day: 16, month: 11, year: 2026),
    );

    expect(service.tasks.length, 1);
    expect(service.tasks.first.title, 'Homework');
    expect(service.tasks.first.isCompleted, false);
    expect(service.tasks.first.isTopPriority, false);
    expect(service.tasks.first.rewardGranted, false);
    expect(service.tasks.first.priority, null);
    expect(service.tasks.first.subTasks.length, 0);
    expect(service.tasks.first.dueDate, null);
    expect(service.tasks.first.dueTime, null);
    expect(service.tasks.first.reminderAt, null);
    expect(service.tasks.first.notes, null);
  });

  test('Cannot set a due time without a due date', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
      ),
    ];
    final service = TaskService(tasks: tasks);

    expect(
      () => service.editTask(
        id: 'T01',
        title: 'Homework',
        dueTime: const TimeOfDay(hour: 17, minute: 0),
      ),
      throwsArgumentError,
    );
    expect(tasks.first.dueTime, null);
  });

  test('Clearing the due date also clears the due time', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        dueDate: DateOnly(day: 20, month: 11, year: 2026),
        dueTime: const TimeOfDay(hour: 17, minute: 0),
      ),
    ];
    final service = TaskService(tasks: tasks);

    service.clearDueDate('T01');

    expect(tasks.first.dueDate, null);
    expect(tasks.first.dueTime, null);
  });

  test('Moving a task shifts its reminder and keeps the deadline', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        dueDate: DateOnly(day: 20, month: 11, year: 2026),
        reminderAt: DateTime(2026, 11, 17, 9, 0),
      ),
    ];
    final service = TaskService(tasks: tasks);

    service.moveTask(
      taskId: 'T01',
      newWorkDay: DateOnly(day: 18, month: 11, year: 2026),
    );

    expect(tasks.first.workDay.isSameDay(DateOnly(day: 18, month: 11, year: 2026)), true);
    expect(tasks.first.reminderAt, DateTime(2026, 11, 19, 9, 0));
    expect(tasks.first.dueDate!.isSameDay(DateOnly(day: 20, month: 11, year: 2026)), true);
  });

  test('Moving a task with no reminder does not create one', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
      ),
    ];
    final service = TaskService(tasks: tasks);

    service.moveTask(
      taskId: 'T01',
      newWorkDay: DateOnly(day: 18, month: 11, year: 2026),
    );

    expect(tasks.first.reminderAt, null);
  });

  test('Moving to an earlier day shifts the reminder backward', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 18, month: 11, year: 2026),
        reminderAt: DateTime(2026, 11, 19, 9, 0),
      ),
    ];
    final service = TaskService(tasks: tasks);

    service.moveTask(
      taskId: 'T01',
      newWorkDay: DateOnly(day: 16, month: 11, year: 2026),
    );

    expect(tasks.first.reminderAt, DateTime(2026, 11, 17, 9, 0));
  });

  test('Can choose a different reminder after a move', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        dueDate: DateOnly(day: 20, month: 11, year: 2026),
        reminderAt: DateTime(2026, 11, 17, 9, 0),
      ),
    ];
    final service = TaskService(tasks: tasks);

    service.moveTask(
      taskId: 'T01',
      newWorkDay: DateOnly(day: 18, month: 11, year: 2026),
    );
    service.editTask(
      id: 'T01',
      title: 'Homework',
      dueDate: DateOnly(day: 20, month: 11, year: 2026),
      reminderAt: DateTime(2026, 11, 20, 8, 30),
    );

    expect(tasks.first.reminderAt, DateTime(2026, 11, 20, 8, 30));
  });

  test('No move is saved before a replacement is chosen', () {
    final tasks = [
      Task(id: 'A', title: 'A', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'B', title: 'B', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'C', title: 'C', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'D', title: 'D', workDay: DateOnly(day: 16, month: 11, year: 2026), isTopPriority: true),
    ];
    final service = TaskService(tasks: tasks);
    final tuesday = DateOnly(day: 17, month: 11, year: 2026);

    final choices = service.getMoveChoices(taskId: 'D', newWorkDay: tuesday);

    expect(choices, isNotNull);
    expect(choices!.markedTaskIds, {'A', 'B', 'C'});
    expect(
      () => service.moveTask(taskId: 'D', newWorkDay: tuesday),
      throwsStateError,
    );
    expect(service.getTask('D')!.workDay.isSameDay(DateOnly(day: 16, month: 11, year: 2026)), true);
  });

  test('Cancel keeps dates, reminders, and marks unchanged', () {
    final tasks = [
      Task(id: 'A', title: 'A', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'B', title: 'B', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'C', title: 'C', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(
        id: 'D',
        title: 'D',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        isTopPriority: true,
        reminderAt: DateTime(2026, 11, 16, 9, 0),
      ),
    ];
    final service = TaskService(tasks: tasks);

    // The screen asks for choices, then the user taps Cancel.
    service.getMoveChoices(
      taskId: 'D',
      newWorkDay: DateOnly(day: 17, month: 11, year: 2026),
    );

    expect(service.getTask('D')!.workDay.isSameDay(DateOnly(day: 16, month: 11, year: 2026)), true);
    expect(service.getTask('D')!.reminderAt, DateTime(2026, 11, 16, 9, 0));
    expect(service.getTask('D')!.isTopPriority, true);
    expect(service.getTask('A')!.isTopPriority, true);
    expect(service.getTask('B')!.isTopPriority, true);
    expect(service.getTask('C')!.isTopPriority, true);
  });

  test('Choose one to replace', () {
    final tasks = [
      Task(id: 'A', title: 'A', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'B', title: 'B', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'C', title: 'C', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'D', title: 'D', workDay: DateOnly(day: 16, month: 11, year: 2026), isTopPriority: true),
    ];
    final service = TaskService(tasks: tasks);
    final tuesday = DateOnly(day: 17, month: 11, year: 2026);

    final choices = service.getMoveChoices(taskId: 'D', newWorkDay: tuesday)!;
    service.moveTaskWithReplacement(choices: choices, replaceTaskId: 'B');

    expect(service.getTask('D')!.workDay.isSameDay(tuesday), true);
    expect(service.getTask('D')!.isTopPriority, true);
    expect(service.getTask('B')!.isTopPriority, false);

    int markedOnTuesday = 0;
    for (Task task in tasks) {
      if (task.isTopPriority && task.workDay.isSameDay(tuesday)) {
        markedOnTuesday++;
      }
    }
    expect(markedOnTuesday, 3);
  });

  test('Old choices are rejected when the marked tasks changed', () {
    final tasks = [
      Task(id: 'A', title: 'A', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'B', title: 'B', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'C', title: 'C', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'D', title: 'D', workDay: DateOnly(day: 16, month: 11, year: 2026), isTopPriority: true),
    ];
    final service = TaskService(tasks: tasks);

    final choices = service.getMoveChoices(
      taskId: 'D',
      newWorkDay: DateOnly(day: 17, month: 11, year: 2026),
    )!;

    // Task A loses its mark after the choices were shown.
    service.setTopPriority(taskId: 'A', isTopPriority: false);

    expect(
      () => service.moveTaskWithReplacement(choices: choices, replaceTaskId: 'B'),
      throwsStateError,
    );
    expect(service.getTask('D')!.workDay.isSameDay(DateOnly(day: 16, month: 11, year: 2026)), true);
  });

  test('Cannot mark a fourth task directly', () {
    final tasks = [
      Task(id: 'A', title: 'A', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'B', title: 'B', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'C', title: 'C', workDay: DateOnly(day: 17, month: 11, year: 2026), isTopPriority: true),
      Task(id: 'E', title: 'E', workDay: DateOnly(day: 17, month: 11, year: 2026)),
    ];
    final service = TaskService(tasks: tasks);

    expect(
      () => service.setTopPriority(taskId: 'E', isTopPriority: true),
      throwsStateError,
    );
    expect(service.getTask('E')!.isTopPriority, false);
  });

  test('Completing every step does not complete the task or give coins', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
      ),
    ];
    final service = TaskService(tasks: tasks);

    service.addSubTask(taskId: 'T01', subTaskId: 'S01', title: 'Read');
    service.addSubTask(taskId: 'T01', subTaskId: 'S02', title: 'Write');
    service.setSubTaskCompleted(taskId: 'T01', subTaskId: 'S01', isCompleted: true);
    service.setSubTaskCompleted(taskId: 'T01', subTaskId: 'S02', isCompleted: true);

    expect(tasks.first.subTasks[0].isCompleted, true);
    expect(tasks.first.subTasks[1].isCompleted, true);
    expect(tasks.first.isCompleted, false);
    expect(tasks.first.rewardGranted, false);
  });

  test('Deleting a task removes the task and its steps', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        reminderAt: DateTime(2026, 11, 16, 9, 0),
      ),
      Task(
        id: 'T02',
        title: 'Other',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
      ),
    ];
    final service = TaskService(tasks: tasks);

    service.addSubTask(taskId: 'T01', subTaskId: 'S01', title: 'Read');
    service.deleteTask('T01');

    expect(tasks.length, 1);
    expect(service.getTask('T01'), null);
    expect(tasks.first.id, 'T02');
    // Cancelling the reminder will be tested with NotificationService.
  });
}