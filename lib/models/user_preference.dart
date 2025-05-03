import 'dart:convert';

class UserPreference {
  final int id;
  final String theme;
  final int textSize;
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final Map<String, dynamic> extraSettings;
  final int profile;

  UserPreference({
    required this.id,
    required this.theme,
    required this.textSize,
    required this.biometricEnabled,
    required this.notificationsEnabled,
    required this.extraSettings,
    required this.profile,
  });

  // Convert JSON to UserPreference Object
  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      id: json['id'],
      theme: json['theme'],
      textSize: json['text_size'],
      biometricEnabled: json['biometric_enabled'],
      notificationsEnabled: json['notifications_enabled'],
      extraSettings: json['extra_settings'] ?? {},
      profile: json['profile'],
    );
  }

  // Convert UserPreference Object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'theme': theme,
      'text_size': textSize,
      'biometric_enabled': biometricEnabled,
      'notifications_enabled': notificationsEnabled,
      'extra_settings': extraSettings,
      'profile': profile,
    };
  }

  // Convert List of JSON to List of UserPreference Objects
  static List<UserPreference> fromJsonList(String str) {
    final List<dynamic> jsonData = json.decode(str);
    return jsonData.map((item) => UserPreference.fromJson(item)).toList();
  }

  // Convert List of UserPreference Objects to JSON String
  static String toJsonList(List<UserPreference> prefs) {
    final List<Map<String, dynamic>> jsonData = prefs.map((pref) => pref.toJson()).toList();
    return json.encode(jsonData);
  }

  // Encode for SharedPreferences
  static String encode(List<UserPreference> prefs) => json.encode(
        prefs.map<Map<String, dynamic>>((pref) => pref.toJson()).toList(),
      );

  // Decode JSON (either from string or API response with `results`)
  static List<UserPreference> decode(String jsonStr) {
    final decoded = json.decode(jsonStr);

    if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
      return (decoded['results'] as List<dynamic>)
          .map((item) => UserPreference.fromJson(item))
          .toList();
    }

    if (decoded is List<dynamic>) {
      return decoded.map((item) => UserPreference.fromJson(item)).toList();
    }

    throw Exception("Invalid JSON format for UserPreference");
  }

    UserPreference copyWith({
    bool? notifications,
    String? theme,
    int? textSize,
  }) {
    return UserPreference(
      id: id,
      theme: theme ?? this.theme,
      textSize: textSize ?? this.textSize,
      biometricEnabled: biometricEnabled,
      notificationsEnabled: notifications ?? this.notificationsEnabled,
      extraSettings: extraSettings,
      profile: profile,
    );
  }

}
