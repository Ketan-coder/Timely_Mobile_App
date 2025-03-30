import 'dart:convert';

class Reminder {
  final int id;
  final String remainderUuid;
  final String title;
  final String body;
  final DateTime alertTime;
  final bool isOver;
  final bool isCompleted;
  final bool isFavourite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int author;

  Reminder({
    required this.id,
    required this.remainderUuid,
    required this.title,
    required this.body,
    required this.alertTime,
    required this.isOver,
    required this.isCompleted,
    required this.isFavourite,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  // Factory constructor to create a Reminder from a JSON map
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      remainderUuid: json['remainder_uuid'],
      title: json['title'],
      body: json['body'],
      alertTime: DateTime.parse(json['alert_time']),
      isOver: json['is_over'],
      isCompleted: json['is_completed'],
      isFavourite: json['is_favourite'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      author: json['author'],
    );
  }

  // Convert Reminder object to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remainder_uuid': remainderUuid,
      'title': title,
      'body': body,
      'alert_time': alertTime.toIso8601String(),
      'is_over': isOver,
      'is_completed': isCompleted,
      'is_favourite': isFavourite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author': author,
    };
  }

  // Convert JSON string to Reminder object
  static Reminder fromJsonString(String jsonString) {
    return Reminder.fromJson(json.decode(jsonString));
  }

  // Convert Reminder object to JSON string
  String toJsonString() {
    return json.encode(toJson());
  }

  static String encode(List<Reminder> reminder) => json.encode(
    reminder
        .map<Map<String, dynamic>>((reminder) => reminder.toJson())
        .toList(),
  );

  static List<Reminder> decode(String reminder) {
    final decodedJson = json.decode(reminder);

    //  If it's a map, extract the 'results' list
    if (decodedJson is Map<String, dynamic> &&
        decodedJson.containsKey('results')) {
      return (decodedJson['results'] as List<dynamic>)
          .map<Reminder>(
            (item) => Reminder.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    // ✅ If it's already a list, decode normally
    if (decodedJson is List<dynamic>) {
      return decodedJson
          .map<Reminder>(
            (item) => Reminder.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception("Invalid JSON format for Reminder");
  }
}
