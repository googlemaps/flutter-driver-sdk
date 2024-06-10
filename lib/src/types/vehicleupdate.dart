// Copyright 2024 Google LLC
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

import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'ridesharing_vehicle_state.dart';

/// Object representing a vehicle update.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
class VehicleUpdate {
  /// Constructs a [TaskInfo] instance.
  VehicleUpdate({
    required this.location,
    required this.vehicleState,
    required this.destinationWaypoint,
    required this.route,
    required this.remainingTimeInSeconds,
    required this.remainingDistanceInMeters,
  });

  /// Returns the current location of the vehicle.
  final LatLng? location;

  /// Returns the current state of the vehicle.
  /// Used only in ridesharing, returns null in the delivery driver case.
  final VehicleState? vehicleState;

  /// Returns the current destination waypoint.
  final NavigationWaypoint? destinationWaypoint;

  /// Returns the current route.
  final List<LatLng?>? route;

  /// Returns the estimated remaining time until reaching the destination.
  final Duration? remainingTimeInSeconds;

  /// Returns the estimated remaining distance until reaching the destination.
  final int? remainingDistanceInMeters;
}
