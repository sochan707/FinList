class TaskGroup {
  final String id;
  final String name;

  TaskGroup({
    required this.id,
    required this.name,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Group ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Group name cannot be empty');
    }
  }
}