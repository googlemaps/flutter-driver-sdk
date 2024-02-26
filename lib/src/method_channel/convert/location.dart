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

import '../../types/location.dart';

import '../method_channel.dart';

/// [Location] convert extension.
/// @nodoc
extension ConvertLocation on Location {
  /// Converts [Location] to [LocationDto]
  LocationDto toDto() {
    return LocationDto(
        accuracy: accuracy,
        altitude: altitude,
        elapsedRealtimeNanos: elapsedRealtimeNanos,
        bearing: bearing,
        isMock: isMock,
        latitude: latitude,
        longitude: longitude,
        provider: provider,
        speed: speed,
        time: time);
  }
}

/// [LocationDto] convert extension.
/// @nodoc
extension ConvertLocationDto on LocationDto {
  /// Converts [LocationDto] to [Location]
  Location toLocation() {
    return Location(
        accuracy: accuracy,
        altitude: altitude,
        elapsedRealtimeNanos: elapsedRealtimeNanos,
        bearing: bearing,
        isMock: isMock,
        latitude: latitude,
        longitude: longitude,
        provider: provider,
        speed: speed,
        time: time);
  }
}
