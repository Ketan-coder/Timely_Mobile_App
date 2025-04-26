import 'dart:convert';

class SharedNotebook {
  final int id;
  final String sharedNotebookUuid;
  final DateTime sharedAt;
  final String shareableLink;
  final bool canEdit;
  final int notebook;
  final int owner;
  final List<int> sharedTo;

  SharedNotebook({
    required this.id,
    required this.sharedNotebookUuid,
    required this.sharedAt,
    required this.shareableLink,
    required this.canEdit,
    required this.notebook,
    required this.owner,
    required this.sharedTo,
  });

  // Convert JSON to SharedNotebook Object
  factory SharedNotebook.fromJson(Map<String, dynamic> json) {
    return SharedNotebook(
      id: json['id'],
      sharedNotebookUuid: json['sharednotebook_uuid'],
      sharedAt: DateTime.parse(json['shared_at']),
      shareableLink: json['shareable_link'],
      canEdit: json['can_edit'],
      notebook: json['notebook'],
      owner: json['owner'],
      sharedTo: List<int>.from(json['sharedTo']),
    );
  }

  // Convert SharedNotebook Object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sharednotebook_uuid': sharedNotebookUuid,
      'shared_at': sharedAt.toIso8601String(),
      'shareable_link': shareableLink,
      'can_edit': canEdit,
      'notebook': notebook,
      'owner': owner,
      'sharedTo': sharedTo,
    };
  }

  // Convert List of JSON to List of SharedNotebook Objects
  static List<SharedNotebook> fromJsonList(String str) {
    final List<dynamic> jsonData = json.decode(str);
    return jsonData.map((item) => SharedNotebook.fromJson(item)).toList();
  }

  // Convert List of SharedNotebook Objects to List of JSON
  static String toJsonList(List<SharedNotebook> notebooks) {
    final List<Map<String, dynamic>> jsonData = notebooks.map((notebook) => notebook.toJson()).toList();
    return json.encode(jsonData);
  }

  static String encode(List<SharedNotebook> notebooks) => json.encode(
    notebooks.map<Map<String, dynamic>>((notebook) => notebook.toJson()).toList(),
  );

  static List<SharedNotebook> decode(String notebooks) {
    final decodedJson = json.decode(notebooks);

    //  If it's a map, extract the 'results' list
    if (decodedJson is Map<String, dynamic> && decodedJson.containsKey('results')) {
      return (decodedJson['results'] as List<dynamic>)
          .map<SharedNotebook>(
            (item) => SharedNotebook.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    // ✅ If it's already a list, decode normally
    if (decodedJson is List<dynamic>) {
      return decodedJson
          .map<SharedNotebook>(
            (item) => SharedNotebook.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception("Invalid JSON format for SharedNotebooks");
  }
}
