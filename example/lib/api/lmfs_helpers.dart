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

import 'dart:io' show Platform;

import 'package:google_maps_driver/google_maps_driver.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import 'helpers.dart';
import 'lmfs_api.dart';
import 'lmfs_types.dart';

/// Read the environment variables given to the app at build time as
/// dart defines. If the environment variable is not defined, use the
/// default value.
/// See ./tools/backend/docker-compose.yml for the values of these environment
/// variables.
const String _LMFSAndroidBaseUrl = String.fromEnvironment(
    'LMFS_ANDROID_HOST_URL',
    defaultValue: 'http://10.0.2.2:8091');
const String _LMFSiOSBaseUrl = String.fromEnvironment('LMFS_IOS_HOST_URL',
    defaultValue: 'http://localhost:8091');
LMFSApi? _lmfsApiInstance;

LMFSDeliveryConfig? _lmfsDeliveryConfig;

/// Returns the [LMFSDeliveryConfig] that was sent to the LMFS backend.
LMFSDeliveryConfig? get lmfsDeliveryConfig => _lmfsDeliveryConfig;

/// This method returns the sample backend API client for LMFS service.
///
/// Returns the same instance of [LMFSApi] every time.
LMFSApi getLMFSApi() {
  if (_lmfsApiInstance == null) {
    final String baseUrl =
        Platform.isAndroid ? _LMFSAndroidBaseUrl : _LMFSiOSBaseUrl;
    _lmfsApiInstance = LMFSApi(baseUrl);
  }
  return _lmfsApiInstance!;
}

/// Sends initial [LMFSDeliveryConfig] to the LMFS backend and returns the response
/// string.
Future<LMFSManifest> initLMFSBackendForVehicle(
    {required String vehicleId,
    required NavigationWaypoint startLocation,
    required List<NavigationWaypoint> deliveryWaypoints,
    required List<NavigationWaypoint> stopWaypoints}) async {
  final String clientId = getClientId();
  assert(deliveryWaypoints.length == stopWaypoints.length,
      'Equal number of delivery and stop waypoints required by the example.');

  final LMFSVehicle vehicle = LMFSVehicle(
      vehicleId: vehicleId,
      providerId: getProjectId(),
      startLocation: LMFSWaypoint.fromNavigationWaypoint(startLocation));

  final List<LMFSTask> tasks = <LMFSTask>[];
  final List<LMFSStop> stops = <LMFSStop>[];

  for (int i = 0; i < deliveryWaypoints.length; i++) {
    final NavigationWaypoint deliveryWaypoint = deliveryWaypoints[i];
    final NavigationWaypoint stopWaypoint = stopWaypoints[i];

    final String randomString = generateRandomString(6);
    final String taskId = '${vehicleId}_$randomString';
    final String trackingId = '${vehicleId}_$randomString';
    final String stopId = '${vehicleId}_$randomString';

    tasks.add(LMFSTask(
      taskId: taskId,
      plannedWaypoint: LMFSWaypoint.fromNavigationWaypoint(deliveryWaypoint),
      trackingId: trackingId,
      durationSeconds: 60 * 60, // 1 hour
      contactName: 'John Doe',
      taskType: LMFSTaskType.delivery,
    ));

    stops.add(LMFSStop(
      stopId: stopId,
      plannedWaypoint: LMFSWaypoint.fromNavigationWaypoint(stopWaypoint),
      taskIds: <String>[taskId],
    ));
  }

  final LMFSManifest manifest = LMFSManifest(
    clientId: clientId,
    vehicle: vehicle,
    tasks: tasks,
    stops: stops,
    remainingStopIdList: stops.map((LMFSStop stop) => stop.stopId).toList(),
  );
  _lmfsDeliveryConfig = LMFSDeliveryConfig(manifests: <LMFSManifest>[manifest]);

  await getLMFSApi().uploadDeliveryConfig(_lmfsDeliveryConfig!);
  return getLMFSApi().getManifestForClientId(clientId);
}

/// Updates the next stop state of the vehicle in the LMFS backend and returns
/// the updated manifest.
Future<LMFSManifest> updateLMFSStopState(
    LMFSManifest manifest, VehicleStopState state) async {
  final LMFSManifestUpdate update = LMFSManifestUpdate(currentStopState: state);
  return getLMFSApi().updateManifest(update, manifest.vehicle.vehicleId);
}

/// Completes the current stop by removing it from the manifest and returns
/// the updated manifest.
Future<LMFSManifest> completeFirstLMFSStop(LMFSManifest manifest) async {
  assert(
      manifest.remainingStopIdList != null &&
          manifest.remainingStopIdList!.isNotEmpty,
      'There should be at least one stop remaining in the manifest.');
  final LMFSManifestUpdate update =
      LMFSManifestUpdate(remainingStopIdList: manifest.remainingStopIdList);
  update.remainingStopIdList!.removeAt(0);
  update.currentStopState =
      update.remainingStopIdList!.isEmpty ? null : VehicleStopState.newStop;
  return getLMFSApi().updateManifest(update, manifest.vehicle.vehicleId);
}

/// Returns the list of [VehicleStop] objects from the given [LMFSManifest].
List<VehicleStop> getStopsFromLMFSManifest(LMFSManifest manifest) {
  final List<VehicleStop> stops = manifest.stops
      .where((LMFSStop stop) =>
          manifest.remainingStopIdList?.contains(stop.stopId) ?? false)
      .map((LMFSStop stop) => VehicleStop(
            vehicleStopState: stop.stopId == manifest.remainingStopIdList?.first
                ? (manifest.currentStopState ?? VehicleStopState.newStop)
                : VehicleStopState.newStop,
            waypoint: stop.plannedWaypoint.toNavigationWaypoint(),
            taskInfoList: stop.taskIds.map((String taskId) {
              final LMFSTask task = manifest.tasks
                  .firstWhere((LMFSTask task) => task.taskId == taskId);
              return TaskInfo(
                taskId: taskId,
                durationSeconds: task.durationSeconds,
              );
            }).toList(),
          ))
      .toList();
  return stops;
}
