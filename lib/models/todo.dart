import 'dart:convert';

class Todo {
  final int id;
  final String todoUuid;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int author;

  Todo({
    required this.id,
    required this.todoUuid,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  // Convert JSON to Todo Object
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      todoUuid: json['todo_uuid'],
      title: json['title'],
      isCompleted: json['is_completed'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      author: json['author'],
    );
  }

  // Convert Todo Object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo_uuid': todoUuid,
      'title': title,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author': author,
    };
  }

  // Convert List of JSON to List of Todo Objects
  static List<Todo> fromJsonList(String str) {
    final List<dynamic> jsonData = json.decode(str);
    return jsonData.map((item) => Todo.fromJson(item)).toList();
  }

  // Convert List of Todo Objects to List of JSON
  static String toJsonList(List<Todo> todos) {
    final List<Map<String, dynamic>> jsonData = todos.map((todo) => todo.toJson()).toList();
    return json.encode(jsonData);
  }

  static String encode(List<Todo> todo) => json.encode(
    todo
        .map<Map<String, dynamic>>((todo) => todo.toJson())
        .toList(),
  );

  static List<Todo> decode(String todos) {
    final decodedJson = json.decode(todos);

    //  If it's a map, extract the 'results' list
    if (decodedJson is Map<String, dynamic> &&
        decodedJson.containsKey('results')) {
      return (decodedJson['results'] as List<dynamic>)
          .map<Todo>(
            (item) => Todo.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    // ✅ If it's already a list, decode normally
    if (decodedJson is List<dynamic>) {
      return decodedJson
          .map<Todo>(
            (item) => Todo.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception("Invalid JSON format for Notebooks");
  }
}
