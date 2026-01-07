import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Firestore REST API client for desktop platforms
/// Since FlutterFire doesn't support Linux/Windows natively, 
/// we use the REST API for Firestore operations on desktop.
class FirestoreRestClient {
  final String projectId;
  String? _idToken;
  
  FirestoreRestClient({required this.projectId});
  
  /// Set the auth token for authenticated requests
  void setAuthToken(String? token) {
    _idToken = token;
  }
  
  /// Base URL for Firestore REST API
  String get _baseUrl => 
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  
  /// Get request headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_idToken != null) 'Authorization': 'Bearer $_idToken',
  };
  
  /// Get a document by path
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$collection/$docId'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDocument(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('Firestore GET error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Firestore GET exception: $e');
      return null;
    }
  }
  
  /// Create or update a document
  Future<bool> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      final firestoreData = _toFirestoreFormat(data);
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/$collection/$docId'),
        headers: _headers,
        body: json.encode({'fields': firestoreData}),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Firestore SET error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Firestore SET exception: $e');
      return false;
    }
  }
  
  /// Update specific fields in a document
  Future<bool> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      final firestoreData = _toFirestoreFormat(data);
      final fieldPaths = data.keys.join(',');
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/$collection/$docId?updateMask.fieldPaths=$fieldPaths'),
        headers: _headers,
        body: json.encode({'fields': firestoreData}),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Firestore UPDATE error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Firestore UPDATE exception: $e');
      return false;
    }
  }
  
  /// Parse Firestore document format to regular Map
  Map<String, dynamic>? _parseDocument(Map<String, dynamic> doc) {
    if (!doc.containsKey('fields')) return null;
    
    final fields = doc['fields'] as Map<String, dynamic>;
    final result = <String, dynamic>{};
    
    for (final entry in fields.entries) {
      result[entry.key] = _parseValue(entry.value);
    }
    
    return result;
  }
  
  /// Parse a Firestore value to Dart value
  dynamic _parseValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('integerValue')) return int.tryParse(value['integerValue'].toString());
    if (value.containsKey('doubleValue')) return value['doubleValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('timestampValue')) return DateTime.tryParse(value['timestampValue']);
    if (value.containsKey('mapValue')) {
      final fields = value['mapValue']['fields'] as Map<String, dynamic>?;
      if (fields == null) return {};
      return fields.map((k, v) => MapEntry(k, _parseValue(v)));
    }
    if (value.containsKey('arrayValue')) {
      final values = value['arrayValue']['values'] as List<dynamic>?;
      if (values == null) return [];
      return values.map((v) => _parseValue(v)).toList();
    }
    return null;
  }
  
  /// Convert Dart Map to Firestore format
  Map<String, dynamic> _toFirestoreFormat(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    
    for (final entry in data.entries) {
      result[entry.key] = _toFirestoreValue(entry.value);
    }
    
    return result;
  }
  
  /// Convert a Dart value to Firestore value format
  Map<String, dynamic> _toFirestoreValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is DateTime) return {'timestampValue': value.toUtc().toIso8601String()};
    if (value is Map<String, dynamic>) {
      return {'mapValue': {'fields': _toFirestoreFormat(value)}};
    }
    if (value is List) {
      return {'arrayValue': {'values': value.map((v) => _toFirestoreValue(v)).toList()}};
    }
    return {'stringValue': value.toString()};
  }
}

/// Check if we're on desktop platform
bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}
