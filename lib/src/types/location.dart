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

import 'package:flutter/foundation.dart';

/// Describes a location.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
@immutable
class Location {
  /// Constructs a [Location] instance.
  const Location(
      {this.accuracy,
      this.altitude,
      this.elapsedRealtimeNanos,
      this.bearing,
      this.isMock,
      this.latitude,
      this.longitude,
      this.provider,
      this.speed,
      this.time});

  /// Horizontal accuracy in meters of this location.
  final double? accuracy;

  /// Altitude of this location in meters above the WGS84 reference ellipsoid.
  final double? altitude;

  /// Time of this location in nanoseconds of elapsed realtime since system boot.
  final int? elapsedRealtimeNanos;

  /// Bearing at the time of this location, in degrees.
  final double? bearing;

  /// Whether this location is marked as a mock location.
  final bool? isMock;

  /// The latitude of this location.
  final double? latitude;

  /// The longitude of this location.
  final double? longitude;

  /// The name of the provider associated with this location
  final String? provider;

  /// The speed at the time of this location, in meters per second.
  final double? speed;

  /// The Unix epoch time of this location fix, in milliseconds since the start
  /// of the Unix epoch (00:00:00 January 1 1970 UTC).
  final int? time;
}
