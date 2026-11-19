
class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final int order;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.order,
  });
}
