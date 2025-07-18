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

import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import 'helpers.dart';
import 'odrd_api.dart';
import 'odrd_types.dart';

/// Read the environment variables given to the app at build time as
/// dart defines. If the environment variable is not defined, use the
/// default value.
/// See ./tools/backend/docker-compose.yml for the values of these environment
/// variables.
const String _odrdAndroidBaseUrl = String.fromEnvironment(
    'ODRD_ANDROID_HOST_URL',
    defaultValue: 'http://10.0.2.2:8092');
const String _odrdiOSBaseUrl = String.fromEnvironment('ODRD_IOS_HOST_URL',
    defaultValue: 'http://localhost:8092');

ODRDApi? _odrdApiInstance;

/// This method returns the sample backend API client for ODRD service.
///
/// Returns the same instance of [ODRDApi] every time.
ODRDApi getODRDApi() {
  if (_odrdApiInstance == null) {
    final String baseUrl =
        Platform.isAndroid ? _odrdAndroidBaseUrl : _odrdiOSBaseUrl;
    _odrdApiInstance = ODRDApi(baseUrl);
  }
  return _odrdApiInstance!;
}

/// Creates a trip in the ODRD backend.
Future<ODRDTrip> createODRDTrip({
  required NavigationWaypoint pickup,
  required NavigationWaypoint dropoff,
  List<NavigationWaypoint>? intermediateDestinations,
  ODRDTripType? triptype,
}) async {
  assert(pickup.target != null, 'pickup.target is required');
  assert(dropoff.target != null, 'dropoff.target is required');
  assert(
      intermediateDestinations == null ||
          intermediateDestinations
              .every((NavigationWaypoint e) => e.target != null),
      'each intermediateDestinations must have target property set');

  final ODRDApi odrdApi = getODRDApi();

  final ODRDCreateTrip createTrip = ODRDCreateTrip(
    triptype: triptype ?? ODRDTripType.exclusive,
    pickup: pickup.target!,
    dropoff: dropoff.target!,
    intermediateDestinations: intermediateDestinations
        ?.map((NavigationWaypoint e) => e.target!)
        .toList(),
  );

  final ODRDTrip trip = await odrdApi.createTrip(createTrip);
  return trip;
}

/// Updates a trip in the ODRD backend.
Future<ODRDTrip> updateODRDTrip(
    {required String tripId, required ODRDTripUpdate update}) async {
  final ODRDApi odrdApi = getODRDApi();
  final ODRDTrip trip = await odrdApi.updateTrip(tripId, update);
  return trip;
}

/// Creates a vehicle in the ODRD backend and returns the initialized vehicle.
Future<ODRDVehicle> createODRDVehicle({
  required String vehicleId,
  List<ODRDTripType>? supportedTripTypes,
  bool? backToBackEnabled,
  int? maximumCapacity,
}) async {
  final ODRDApi odrdApi = getODRDApi();
  final String randomString = generateRandomString(6);
  final String vehicleIdWithRandomPrefix = '${vehicleId}_$randomString';

  final ODRDVehicle createVehicle = ODRDVehicle(
    vehicleId: vehicleIdWithRandomPrefix,
    vehicleState: ODRDVehicleState.offline,
    supportedTripTypes: supportedTripTypes,
    backToBackEnabled: backToBackEnabled,
    maximumCapacity: maximumCapacity,
  );

  final ODRDVehicle initializedVehicle =
      await odrdApi.createVehicle(createVehicle);

  return initializedVehicle;
}
