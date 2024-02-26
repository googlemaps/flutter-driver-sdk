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

import 'package:google_maps_navigation/google_maps_navigation.dart';
import '../method_channel.dart';

// These conversion functions have been duplicated between
// google_maps_navigation and google_maps_driver packages.
//
// Keep in sync.

/// [NavigationWaypointDto] convert extension.
/// @nodoc
extension ConvertNavigationWaypointDto on NavigationWaypointDto {
  /// Converts [NavigationWaypointDto] to [NavigationWaypoint]
  NavigationWaypoint toNavigationWaypoint() => NavigationWaypoint(
        title: title,
        target: target?.toLatLng(),
        placeID: placeID,
        preferSameSideOfRoad: preferSameSideOfRoad,
        preferredSegmentHeading: preferredSegmentHeading,
      );
}

/// [NavigationWaypoint] convert extension.
/// @nodoc
extension ConvertNavigationWaypoint on NavigationWaypoint {
  /// Converts [NavigationWaypoint] to [NavigationWaypointDto]
  NavigationWaypointDto toDto() => NavigationWaypointDto(
        title: title,
        target: target?.toDto(),
        placeID: placeID,
        preferSameSideOfRoad: preferSameSideOfRoad,
        preferredSegmentHeading: preferredSegmentHeading,
      );
}
