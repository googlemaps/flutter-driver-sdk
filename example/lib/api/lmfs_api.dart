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

import 'client.dart';
import 'lmfs_types.dart';
import 'shared_types.dart';

/// API client for Last Mile Fleet Solution (LMFS) sample backend.
///
/// Documentation to for these endpoints can be found under following links:
/// https://github.com/googlemaps/last-mile-fleet-solution-samples/tree/main/backend#delivery-configuration-file
class LMFSApi extends ApiClient {
  /// Constructor for [LMFSApi]
  LMFSApi(super.baseUrl);

  /// Method to get the token for a given vehicle ID and [LMFSTokenType]
  Future<TokenResponse> getToken(LMFSTokenType type, String? id) async {
    final String typeStr = type.toJsonString();
    final String response = await get('token/$typeStr/${id ?? ''}');
    return TokenResponse.fromLMFSJson(
      jsonDecode(response) as Map<String, dynamic>,
    );
  }

  /// Method to update the manifest for a given vehicle ID
  Future<LMFSManifest> updateManifest(
    LMFSManifestUpdate manifestDetails,
    String? vehicleId,
  ) async {
    final String endpoint = vehicleId != null
        ? 'manifest/$vehicleId'
        : 'manifest';
    final String response = await post(endpoint, manifestDetails.toJson());
    return LMFSManifest.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Method to get the manifest for a given vehicle ID
  Future<LMFSManifest> getManifest(String vehicleId) async {
    final String response = await get('manifest/$vehicleId');
    return LMFSManifest.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Method to get the manifest for a given client ID
  Future<LMFSManifest> getManifestForClientId(String clientId) async {
    final String response = await post('manifest', <String, String>{
      'client_id': clientId,
    });
    return LMFSManifest.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Method to upload delivery configuration
  Future<String> uploadDeliveryConfig(LMFSDeliveryConfig config) async {
    final String jsonData = jsonEncode(config.toJson());
    return postFile('backend_config', jsonData);
  }

  /// Method to update the task with a given ID
  Future<LMFSTask> updateTask(String taskId, LMFSTask data) async {
    final String response = await post('task/$taskId', data.toJson());
    return LMFSTask.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Method to get the task with a given ID
  Future<LMFSTask> getTaskById(String taskId) async {
    final String response = await get('task/$taskId');
    return LMFSTask.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Method to get the tasks associated with a given vehicle ID
  Future<List<LMFSTask>> getTasksByVehicleId(String vehicleId) async {
    final String response = await get('tasks?vehicleId=$vehicleId');
    final List<dynamic> responseData = jsonDecode(response) as List<dynamic>;
    return List<LMFSTask>.from(
      responseData.map(
        (dynamic task) => LMFSTask.fromJson(task as Map<String, dynamic>),
      ),
    );
  }

  /// Method to get task information by tracking ID
  Future<LMFSTask> getTaskInfoByTrackingId(String trackingId) async {
    final String response = await get('taskInfoByTrackingId/$trackingId');
    return LMFSTask.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }
}
