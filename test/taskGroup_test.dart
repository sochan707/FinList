import 'package:flutter_test/flutter_test.dart';
import '../lib/service/taskGroup_service.dart';
import '../lib/model/taskGroup.dart';
import '../lib/model/task.dart';
import '../lib/model/subTask.dart';
import '../lib/model/dateOnly.dart';

void main() {
  test('Create a group with no space', () {
    final service = TaskGroupService();

    service.createGroup(id: 'G01', name: ' Math ');

    expect(service.groups.length, 1);
    expect(service.groups.first.id, 'G01');
    expect(service.groups.first.name, 'Math');
  });

  test('Cannot create a group with a blank name', () {
    final service = TaskGroupService();

    expect(
      () => service.createGroup(id: 'G01', name: '   '),
      throwsArgumentError,
    );
    expect(service.groups.length, 0);
  });

  test('Cannot create an existing group', () {
    final service = TaskGroupService();

    service.createGroup(id: 'G01', name: 'Math');

    expect(
      () => service.createGroup(id: 'G01', name: 'Work'),
      throwsException,
    );
    expect(service.groups.length, 1);
  });

  test('Can rename a group', () {
    final service = TaskGroupService();

    service.createGroup(id: 'G01', name: 'Math');
    service.renameGroup(id: 'G01', name: ' Science ');

    expect(service.groups.length, 1);
    expect(service.groups.first.name, 'Science');
  });

  test('Cannot rename a group to a blank name', () {
    final service = TaskGroupService();

    service.createGroup(id: 'G01', name: 'Math');

    expect(
      () => service.renameGroup(id: 'G01', name: '   '),
      throwsArgumentError,
    );
    expect(service.groups.first.name, 'Math');
  });

  test('Cannot rename a group that does not exist', () {
    final service = TaskGroupService();

    expect(
      () => service.renameGroup(id: 'G01', name: 'Math'),
      throwsException,
    );
  });

  test('Can assign an ungrouped task to an existing group', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
      ),
    ];
    final service = TaskGroupService(tasks: tasks);
    service.createGroup(id: 'G01', name: 'Math');

    service.assignTaskToGroup(taskId: 'T01', groupId: 'G01');

    expect(tasks.first.groupId, 'G01');
  });

  test('Cannot assign a task to a missing group', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
      ),
    ];
    final service = TaskGroupService(tasks: tasks);

    expect(
      () => service.assignTaskToGroup(taskId: 'T01', groupId: 'G01'),
      throwsException,
    );
    expect(tasks.first.groupId, null);
  });

  test('Cannot assign a task that does not exist', () {
    final service = TaskGroupService();
    service.createGroup(id: 'G01', name: 'Math');

    expect(
      () => service.assignTaskToGroup(taskId: 'T01', groupId: 'G01'),
      throwsException,
    );
  });

  test('Can leave a task ungrouped', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        groupId: 'G01',
      ),
    ];
    final service = TaskGroupService(tasks: tasks);
    service.createGroup(id: 'G01', name: 'Math');

    service.assignTaskToGroup(taskId: 'T01', groupId: null);

    expect(tasks.first.groupId, null);
  });

  test('Deleting a group keeps all tasks and steps and clears group links', () {
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        groupId: 'G01',
        subTasks: [SubTask(id: 'S01', title: 'Read', order: 0)],
      ),
      Task(
        id: 'T02',
        title: 'Report',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        groupId: 'G02',
      ),
      Task(
        id: 'T03',
        title: 'No group',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
      ),
    ];
    final service = TaskGroupService(tasks: tasks);
    service.createGroup(id: 'G01', name: 'Math');
    service.createGroup(id: 'G02', name: 'Work');

    service.deleteGroup('G01');

    expect(service.groups.length, 1);
    expect(service.groups.first.id, 'G02');
    expect(tasks.length, 3);
    expect(tasks[0].groupId, null);
    expect(tasks[0].subTasks.length, 1);
    expect(tasks[1].groupId, 'G02');
    expect(tasks[2].groupId, null);
  });

  test('Cannot delete a group that does not exist', () {
    final service = TaskGroupService();

    expect(() => service.deleteGroup('G01'), throwsException);
  });

  test('If saving fails when deleting a group, nothing changes', () {
    final groups = [TaskGroup(id: 'G01', name: 'Math')];
    final tasks = [
      Task(
        id: 'T01',
        title: 'Homework',
        workDay: DateOnly(day: 16, month: 11, year: 2026),
        groupId: 'G01',
      ),
    ];
    final service = TaskGroupService(
      groups: groups,
      tasks: tasks,
      saveChanges: (newGroups, newTasks) {
        throw Exception('Disk error');
      },
    );

    expect(() => service.deleteGroup('G01'), throwsException);
    expect(groups.length, 1);
    expect(tasks.first.groupId, 'G01');
  });
}