class User {
  final int id;
  final String userId;
  final String title;
  final bool completed;
  User({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      userId: (json['userId'] as int).toString(),
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }
  Map<String, dynamic> toJson() {
    return {'id': id, 'userId': userId, 'title': title, 'completed': completed};
  }
}

// {
// userId: 1,
// id: 1,
// title: "delectus aut autem",
// completed: false
// }
