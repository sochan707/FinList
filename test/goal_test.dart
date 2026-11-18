
import 'package:flutter_test/flutter_test.dart';
import '../lib/service/goal_service.dart';

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
}
