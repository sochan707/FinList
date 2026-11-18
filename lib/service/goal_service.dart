
import '../model/goal.dart';

class GoalService {
  final List<Goal> goals = [];

  //Create goal
  void createGoal({required String id, required String title, String? description,}) {
    //Goal shall not exis
    if (_findGoalOrNull(id) != null) {
      throw Exception('Goal $id already exists');
    }

    goals.add(Goal(id: id, title: title.trim(), description: description,),);
  }

  //Edit goal
  void editGoal({required String id, required String title,  String? description,}) {
    for (int i = 0; i < goals.length; i++) {
      if (goals[i].id == id) {
          goals[i] = Goal(id: id, title: title.trim(), description: description,);
      return;
    }
  }
    throw Exception('Goal $id not found');
  }

  //Search goal
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

  //Delete goal
  void deleteGoal(String id) {
    // Goal shall exist
    Goal? goal = _findGoalOrNull(id);

    if (goal == null) {
      throw Exception('Goal $id not found');
    }

    goals.remove(goal);
  }

  // ! Find goal
  Goal? _findGoalOrNull(String id) {
    for (Goal g in goals) {
      if (g.id == id) return g;
    }

    return null;
  }
}
