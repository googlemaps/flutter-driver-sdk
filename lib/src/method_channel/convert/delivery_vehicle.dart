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

import '../../../google_driver_flutter.dart';
import '../method_channel.dart';

/// [DeliveryVehicleDto] convert extension.
/// @nodoc
extension ConvertDeliveryVehicleDto on DeliveryVehicleDto {
  /// Converts [DeliveryVehicleDto] to [DeliveryVehicle].
  DeliveryVehicle toDeliveryVehicle() {
    return DeliveryVehicle(
        providerId: providerId,
        id: id,
        name: name,
        stops: stops
            .whereType<VehicleStopDto>()
            .map((VehicleStopDto e) => e.toVehicleStop())
            .toList());
  }
}
