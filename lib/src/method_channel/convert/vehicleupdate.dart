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

import '../../types/types.dart';
import '../method_channel.dart';

/// [VehicleUpdateDto] convert extension.
/// @nodoc
extension ConvertVehicleUpdateDto on VehicleUpdateDto {
  /// Converts Pigeon [VehicleUpdateDto] to Google Driver [VehicleUpdate].
  VehicleUpdate toVehicleUpdate() {
    return VehicleUpdate(
      destinationWaypoint: destinationWaypoint?.toNavigationWaypoint(),
      location: location?.toLatLng(),
      remainingDistanceInMeters: remainingDistanceInMeters?.toInt(),
      remainingTimeInSeconds:
          remainingTimeInSeconds != null
              ? Duration(seconds: remainingTimeInSeconds!.toInt())
              : null,
      route: route?.map((LatLngDto? e) => e?.toLatLng()).toList(),
      vehicleState: vehicleState?.toVehicleState(),
    );
  }
}
