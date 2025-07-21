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

import '../../google_driver_flutter.dart';

///  DeliveryVehicle represents a vehicle used to perform single tracked
///  actions, known as Tasks.
///
/// {@category Delivery Driver}
@immutable
class DeliveryVehicle {
  /// Constructs a [DeliveryVehicle] instance.
  const DeliveryVehicle({
    required this.providerId,
    required this.id,
    required this.name,
    required this.stops,
  });

  /// Returns the unique identifier for this provider.
  final String providerId;

  /// Returns the unique identifier for this vehicle for this provider.
  final String id;

  /// Returns the full name for this vehicle among all providers.
  final String name;

  /// Returns the stops currently assigned to this vehicle as reported by
  /// FleetEngine.
  final List<VehicleStop?> stops;
}
