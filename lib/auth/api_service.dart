import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/services/internet_checker_service.dart';

class ApiService {
  static const String baseUrl = 'https://timely.pythonanywhere.com';

  static Future<void> makeApiCall({
    required String endpoint,
    required InternetChecker internetChecker,
    String token = '',
    String method = 'GET',
    int successStatusCode = 200,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? additionalHeaders,
    int? pageNumber,
    String? objectId,
    bool addContentType = true,
    bool addAuthorization = true,
    Function(Map<String, dynamic>)? onSuccess,
    Function(http.Response)? onFailure,
  }) async {
    if (!internetChecker.isConnected) {
      debugPrint("\n[DEBUG] No internet connection. Skipping API call.");
      showAnimatedSnackBar(
        internetChecker.context,
        "You're offline. Please check your internet connection.",
        isError: true,
        isTop: true,
      );
      return;
    }

    // Build query params
    final Map<String, dynamic> query = {};
    if (queryParams != null) query.addAll(queryParams);
    if (pageNumber != null && pageNumber > 1) query['page'] = pageNumber.toString();

    // Adjust endpoint if objectId is provided for specific methods
    String adjustedEndpoint = endpoint;
    if (objectId != null && ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase())) {
      adjustedEndpoint = '$endpoint$objectId/';
    }

    final uri = (queryParams == null && pageNumber == null)
        ? Uri.parse('$baseUrl$adjustedEndpoint')
        : Uri.parse('$baseUrl$adjustedEndpoint').replace(queryParameters: query);

    // Construct headers dynamically
    final headers = <String, String>{};
    if (addContentType) headers['Content-Type'] = 'application/json';
    if (addAuthorization && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    if (additionalHeaders != null) headers.addAll(additionalHeaders);

    // Debug statements
    debugPrint("\n[DEBUG] Making API Call:");
    debugPrint("  URL ==> $uri");
    debugPrint("  Method ==> $method");
    debugPrint("  Headers ==> $headers");
    if (body != null) debugPrint("  Body ==> $body");
    if (query.isNotEmpty) debugPrint("  Query Params ==> $query");

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        case 'GET':
        default:
          response = await http.get(uri, headers: headers);
          break;
      }

      debugPrint("[DEBUG] Status Code ==> ${response.statusCode}");
      debugPrint("[DEBUG] Response Body ==> ${response.body}");

      if (response.statusCode == successStatusCode) {
        if (method.toUpperCase() == 'DELETE') {
          onSuccess?.call({});
          return;
        }
        if (response.body.isEmpty) {
          onSuccess?.call({});
          return;
        }
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        onSuccess?.call(jsonResponse);
      } else {
        debugPrint("[ERROR] API Error Body: ${response.body}");
        onFailure?.call(response);
      }
    } on SocketException catch (e) {
      debugPrint("[ERROR] SocketException: $e");
      showAnimatedSnackBar(
        internetChecker.context,
        "No internet or DNS issue.",
        isError: true,
        isTop: true,
      );
    } catch (e) {
      debugPrint("[ERROR] Unexpected error: $e");
    }
  }
}
