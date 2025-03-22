import 'dart:convert';

class Notebook {
  final int id;
  final List<String> pages;
  final List<String> sugPages;
  final String notebookUuid;
  final String title;
  final String body;
  final int priority;
  final bool isFavourite;
  final bool isShared;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPasswordProtected;
  final bool isPasswordEntered;
  final bool isAccessedRecently;
  final String? password;
  final int author;
  final List<int> sharedWith;

  Notebook({
    required this.id,
    required this.pages,
    required this.sugPages,
    required this.notebookUuid,
    required this.title,
    required this.body,
    required this.priority,
    required this.isFavourite,
    required this.isShared,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    required this.isPasswordProtected,
    required this.isPasswordEntered,
    required this.isAccessedRecently,
    this.password,
    required this.author,
    required this.sharedWith,
  });

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'],
      pages: List<String>.from(json['pages']),
      sugPages: List<String>.from(json['sugpages']),
      notebookUuid: json['notebook_uuid'],
      title: json['title'],
      body: json['body'],
      priority: json['priority'],
      isFavourite: json['is_favourite'],
      isShared: json['is_shared'],
      isPublic: json['is_public'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isPasswordProtected: json['is_password_protected'],
      isPasswordEntered: json['is_password_entered'],
      isAccessedRecently: json['is_accessed_recently'],
      password: json['password'] ?? "",
      author: json['author'],
      sharedWith: List<int>.from(json['shared_with']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pages': pages,
      'sugpages': sugPages,
      'notebook_uuid': notebookUuid,
      'title': title,
      'body': body,
      'priority': priority,
      'is_favourite': isFavourite,
      'is_shared': isShared,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_password_protected': isPasswordProtected,
      'is_password_entered': isPasswordEntered,
      'is_accessed_recently': isAccessedRecently,
      'password': password ?? "",
      'author': author,
      'shared_with': sharedWith,
    };
  }

  static String encode(List<Notebook> notebooks) => json.encode(
    notebooks
        .map<Map<String, dynamic>>((notebook) => notebook.toJson())
        .toList(),
  );

  //static List<Notebook> decode(String notebooks) =>
  //    (json.decode(notebooks) as List<dynamic>).map<Notebook>((item) => Notebook.fromJson(item)).toList();
  static List<Notebook> decode(String notebooks) {
    final decodedJson = json.decode(notebooks);

    //  If it's a map, extract the 'results' list
    if (decodedJson is Map<String, dynamic> &&
        decodedJson.containsKey('results')) {
      return (decodedJson['results'] as List<dynamic>)
          .map<Notebook>(
            (item) => Notebook.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    // ✅ If it's already a list, decode normally
    if (decodedJson is List<dynamic>) {
      return decodedJson
          .map<Notebook>(
            (item) => Notebook.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception("Invalid JSON format for Notebooks");
  }
}
