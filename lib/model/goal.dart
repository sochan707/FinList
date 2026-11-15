
class Goal {
  final String id;
  final String title;
  final String? description;

  // Constructor
  Goal({
    required this.id, required String title, this.description,
  }) : title = title.trim() {
    // Check if ID is empty.
    if (id.trim().isEmpty) {
      throw ArgumentError('Goal ID is required');
    }

    // Check if title is empty.
    if (title.trim().isEmpty) {
      throw ArgumentError('Goal title cannot be empty');
    }
  }

  // Create a new Goal with updated information.
  Goal copyWith({
    String? title,
    String? description,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}
