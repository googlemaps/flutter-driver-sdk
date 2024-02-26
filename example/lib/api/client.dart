// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base class for API clients communicating with REST Sample backends.
abstract class ApiClient {
  /// Constructor for [ApiClient]
  ApiClient(this.baseUrl);

  /// Base URL for the API
  final String baseUrl;

  /// Helper method to check if backend is running
  Future<bool> backendIsRunning() async {
    try {
      final String response = await get('');
      return response != '';
    } on Exception catch (_) {
      return false;
    }
  }

  /// Method to get data from the API
  ///
  /// Returns the response body as a string
  Future<String> get(String endpoint) async {
    return _parseResponse(await http.get(Uri.parse('$baseUrl/$endpoint')));
  }

  /// Method to post data to the API
  ///
  /// Returns the response body as a string
  Future<String> post(String endpoint, Map<String, dynamic> body) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  /// Method to put data to the API
  ///
  /// Returns the response body as a string
  Future<String> put(String endpoint, Map<String, dynamic> body) async {
    final http.Response response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  /// Method to post file to the API
  ///
  /// Returns the response body as a string
  Future<String> postFile(String endpoint, String data) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));

    // Adding file data
    request.files.add(http.MultipartFile.fromString('file', data));

    final http.StreamedResponse streamedResponse = await request.send();
    final http.Response response =
        await http.Response.fromStream(streamedResponse);

    return _parseResponse(response);
  }

  /// Method to parse the response from the API
  String _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      return response.body;
    } else {
      debugPrint(response.body);
      throw Exception('Failed to communicate with the server, status code: '
          '${response.statusCode}.');
    }
  }
}
