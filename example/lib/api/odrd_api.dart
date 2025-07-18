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
import 'odrd_types.dart';
import 'shared_types.dart';

/// API client for On-demand Rides and Deliveries Solution (ODRD)
/// sample backend.
///
/// Documentation to for these endpoints can be found under following links:
/// https://github.com/googlemaps/java-on-demand-rides-deliveries-stub-provider?tab=readme-ov-file#endpoints
class ODRDApi extends ApiClient {
  /// Constructor for [ODRDApi]
  ODRDApi(super.baseUrl);

  /// Retrieves an authentication token for a specified vehicle ID
  /// and token type.
  ///
  /// Returns a [TokenResponse] containing the token details.
  Future<TokenResponse> getToken(ODRDTokenType type, String? vehicleId) async {
    final String typeStr = type.toJsonString();
    final String response = await get('token/$typeStr/${vehicleId ?? ''}');
    return TokenResponse.fromODRDJson(
      jsonDecode(response) as Map<String, dynamic>,
    );
  }

  /// Creates a new vehicle in the ODRD backend with the specified details.
  Future<ODRDVehicle> createVehicle(ODRDVehicle vehicle) async {
    final String response = await post('vehicle/new', vehicle.toJson());
    return ODRDVehicle.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Get a vehicle from the ODRD backend.
  Future<ODRDVehicle> getVehicle(String vehicleId) async {
    final String response = await get('vehicle/$vehicleId');
    return ODRDVehicle.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Get all vehicles from the ODRD backend.
  Future<List<ODRDVehicle>> getVehicles() async {
    final String response = await get('vehicles/');
    return (jsonDecode(response) as List<dynamic>)
        .map((dynamic e) => ODRDVehicle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Fetches the details of a trip from the ODRD backend using the trip ID.
  Future<ODRDTrip> getTrip(String tripId) async {
    final String response = await get('trip/$tripId');
    return ODRDTrip.fromJson(
      (jsonDecode(response) as Map<String, dynamic>)['trip']
          as Map<String, dynamic>,
    );
  }

  /// Creates a new trip in the ODRD backend with the given trip data.
  Future<ODRDTrip> createTrip(ODRDCreateTrip trip) async {
    final String response = await post('trip/new', trip.toJson());
    return ODRDTrip.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Updates the trip using [tripId] at the ODRD backend with the given update.
  Future<ODRDTrip> updateTrip(String tripId, ODRDTripUpdate update) async {
    final String response = await put('trip/$tripId', update.toJson());
    return ODRDTrip.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }
}
