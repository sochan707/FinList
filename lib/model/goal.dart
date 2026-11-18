class Goal{
  final String id;
  final String title;
  final String? description;

  Goal({
    required this.id, 
    required this.title,
    this.description
  }){
    if(id.trim().isEmpty){
      throw ArgumentError('Goal ID cannot be empty');
    }
    if(title.trim().isEmpty){
      throw ArgumentError('Goal title cannot be empty');
    }
  }
}